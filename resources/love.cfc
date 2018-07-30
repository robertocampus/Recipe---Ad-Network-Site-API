<cfcomponent extends="taffyAPI.base" taffy:uri="/love/{entityTypeID}/{entityID}/{userID}/" hints="User can like/dislike an Entity. That entity can be blog, recipe or anything else.">
	
	<cffunction name="POST" access="public" output="false" hint="User can like the item of entity" auth="true">
		<cfargument name="entityTypeID" type="numeric" required="yes" hint="ID of entity type. ie. 10 = recipe; 1 = blog; etc.">
		<cfargument name="entityID" type="numeric" required="yes" hint="ID of entity's item.">
		<cfargument name="userID" type="numeric" required="yes" hint="User ID.">
		<cfargument name="auth_token" type="string" required="yes" hint="User authorization token (auth_token)">

		<cfset local.qry = "" />
		<cfset local.entityTypeQuery = "" />
		<cfset local.entityItemQuery = "" />
		<cfset result = structNew()>
		<cfset result['message'] = ''>
		<cfset result['status'] = ''>

		<cftry>

			<!--- check entity type is available or not. if available, continue to next steps --->
			<cfquery name="local.entityTypeQuery" dbtype="query">
				SELECT entityTable FROM application.val_tables.val_entityType
					WHERE entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer" >
			</cfquery>

			<cfif local.entityTypeQuery.recordCount >

				<cfset pkStruct = {"items":"itemID", "images":"imageID", "blogs":"blogID", "users":"userID", "contests":"contestID", "recipes":"recipeID"}>
				
				<!--- check entity is available or not. if available, continue to next steps --->
				<cfif structKeyExists( pkStruct, local.entityTypeQuery.entityTable )>

					<cfquery name="local.entityItemQuery" datasource="#variables.datasource#" >
						SELECT * FROM #local.entityTypeQuery.entityTable#
							WHERE #pkStruct[local.entityTypeQuery.entityTable]# = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer" >
					</cfquery>

				</cfif>

				<!--- To prevent duplicate records. it returns already exist or not --->
				<cfquery datasource="#variables.datasource#" name="loveIsExist">
					SELECT * FROM loved 
						WHERE entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
							AND entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
							AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
				</cfquery>

				<cfif local.entityItemQuery.recordCount AND NOT loveIsExist.recordCount >

					<cfquery datasource="#variables.datasource#" name="local.qry">
						INSERT INTO loved (
											entityTypeID,
											entityID,
											userID,
											lovedDate
											)
						VALUES ( 
								<cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">,
								<cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">,
								<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">,
								<cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp"> 
								)
					</cfquery>

					<cfset updateloveCount( entityTypeID = arguments.entityTypeID, entityID = arguments.entityID,value= 1 )>

				<cfelse>
					<cfset result.message = application.messages['love_get_found_error']>
					<cfreturn representationOf(result).withStatus(404) />
				</cfif>

			<cfelse>
				<cfset result.message = application.messages['love_get_found_error']>
				<cfreturn representationOf(result).withStatus(404) />
			</cfif>
			
			<cfcatch>

				<cfset logAction( actionID = 359, extra = "method: /love/POST", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>
		
		<cfset result.status  	= true />
		<cfset result.message = application.messages['love_post_add_success']/>

	  	<cfset logAction( actionID = 358, extra = "method: /love/POST" )>

		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>


	<cffunction name="GET" access="public" output="false" hint="User can like the item of entity" >
		<cfargument name="entityTypeID" type="numeric" required="yes" hint="ID of entity type. ie. 10 = recipe; 1 = blog; etc.">
		<cfargument name="entityID" type="numeric" required="yes" hint="ID of entity's item.">
		<cfargument name="userID" type="numeric" required="yes" hint="User ID.">

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />
		<cfset local.entityTypeQuery = "" />	

		<cftry>

			<cfquery name="local.entityTypeQuery" dbtype="query">
				SELECT entityTable FROM application.val_tables.val_entityType
					WHERE entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer" >
			</cfquery>

			<cfif local.entityTypeQuery.recordCount >

				<cfset pkStruct = {"items":"itemID", "images":"imageID", "blogs":"blogID", "users":"userID", "contests":"contestID", "recipes":"recipeID"}>

				<cfquery datasource="#variables.datasource#" name="result.query" >
					SELECT 
						ve.entityTypeName, 
						u.username,
						u.userEmail,
						en.*

					FROM loved l 
					INNER JOIN val_entityType ve ON l.entityTypeID = ve.entityTypeID
					LEFT JOIN users u ON l.userID = u.userID

					<cfif structKeyExists( pkStruct, local.entityTypeQuery.entityTable ) >
						LEFT JOIN #local.entityTypeQuery.entityTable# en ON l.entityID = en.#pkStruct[local.entityTypeQuery.entityTable]#
					</cfif>

					WHERE l.entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
					AND l.entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
					AND l.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
				</cfquery>

			<cfelse>
				<cfset result.message = application.messages['love_get_found_error']>
				<cfreturn noData().withStatus(404) />
			</cfif>

			<cfif result.query.recordCount EQ 0 >
				<cfset result.message = application.messages['love_get_found_error']>
				<cfreturn noData().withStatus(404) />
			</cfif>

			<cfcatch>

				<cfset logAction( actionID = 364, extra = "method: /love/GET", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>

		<cfset result.status  	= true />
		<cfset result.message = application.messages['love_get_found_success'] />

	  	<cfset logAction( actionID = 363, extra = "method: /love/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="DELETE" access="public" output="false" hint="User can dislike the entity if they had previously liked the entity." auth="true">
		<cfargument name="entityTypeID" type="numeric" required="yes" hint="ID of entity type. ie. 10 = recipe; 1 = blog; etc.">
		<cfargument name="entityID" type="numeric" required="yes" hint="ID of entity's item.">
		<cfargument name="userID" type="numeric" required="yes" hint="User ID.">
		<cfargument name="auth_token" type="string" required="yes" hint="User authorization token (auth_token)">

		
		<cfset local.qry = "">
		<cftry>
			
			<cfquery datasource="#variables.datasource#" name="local.qry" result="isDeleted">
				DELETE FROM loved 
					WHERE entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
						AND entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
						AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
						LIMIT 1
			</cfquery>

			<cfcatch>

				<cfset logAction( actionID = 361, extra = "method: /love/DELETE", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn noData().withStatus(500) />
				
			</cfcatch>

		</cftry>

		<cfset statusCode = ( isDeleted.recordCount GT 0 ) ? 200 : 404 >

		<cfif statusCode EQ 200>
			<cfset updateloveCount( entityTypeID = arguments.entityTypeID, entityID = arguments.entityID, value = -1 )>
		</cfif>

		<cfset result.status  	= true />
		<cfset result.message = statusCode EQ 200 ? application.messages['love_delete_remove_success'] : application.messages['love_delete_remove_error'] />

	  	<cfset logAction( actionID = 360, extra = "method: /love/DELETE" )>

		<cfreturn noData().withStatus(statusCode) />
	</cffunction>

	
	<cffunction name="updateloveCount" access ="private" output="false">
		<cfargument name = "entityTypeID" 	type="string"  required="false" default="">
		<cfargument name = "entityID" 		type="numeric" required="false" default="0">
		<cfargument name = "value" 			type="numeric" required="false" default="0">

		<cfquery name="local.entityTypeQuery" datasource="#variables.datasource#" >
			SELECT entityTable FROM val_entityType
			WHERE entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer" >
		</cfquery>

		<cfset pkStruct = { "recipes":["recipeID","recipeTotalLoves"] }>

		<cfquery name="local.qry" datasource="#variables.datasource#">
			
			UPDATE #local.entityTypeQuery.entityTable#  SET
					#pkStruct[local.entityTypeQuery.entityTable][2]# = #pkStruct[local.entityTypeQuery.entityTable][2]#+(#arguments.value#) 
			WHERE #pkStruct[local.entityTypeQuery.entityTable][1]# = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">

		</cfquery>

	</cffunction>

</cfcomponent> 