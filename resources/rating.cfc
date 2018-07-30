
<cfcomponent extends="taffyAPI.base" taffy:uri="/rating/{entityTypeID}/{entityID}/{userID}/" hints="Users can provide rating and remove the rating for an item of particular Entity. The Entity will be blog, recipe or anything else.">

	<cffunction name="POST" access="public" output="false" hint="If user provide rating for item of entity, the rating will store in database" auth="true">
		<cfargument name="entityTypeID" type="numeric" required="yes" hint="ID of entity">
		<cfargument name="entityID" type="numeric" required="yes" hint="ID of entity's item.">
		<cfargument name="userID" type="numeric" required="yes" hint="User ID.">
		<cfargument name="rating" type="numeric" required="yes" hint="The user pass rating as numeric value out of 10.">
		<cfargument name="auth_token" type="string" required="yes" hint="User authorization token (auth_token)">

		<cfset local.qry = "" />
		<cfset local.entityTypeQuery = "" />
		<cfset local.entityItemQuery = "" />
		<cfset result = structNew()>
		<cfset result['status'] = false>
		<cfset result['message'] = ''>
		<cftry>

			<!--- check entity type is available or not. if available, continue to next steps --->
			<cfquery name="local.entityTypeQuery" dbtype="query" >
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
				<cfquery datasource="#variables.datasource#" name="ratingIsExist">
					SELECT * FROM ratings 
						WHERE entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
							AND entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
							AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
				</cfquery>

				<cfif local.entityItemQuery.recordCount >
					
					<cfif NOT ratingIsExist.recordCount >
						
						<!--- New rating for an entity --->
						<cfquery datasource="#variables.datasource#" name="local.qry">
							INSERT INTO ratings (
														entityTypeID,
														entityID,
														userID,
														rating,
														ratingDate		
														)
							VALUES (
									<cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">,
									<cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">,
									<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">,
									<cfqueryparam value="#arguments.rating#" cfsqltype="cf_sql_integer">,
									<cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">
									)
						</cfquery>

						<cfset UpdateRecipeRating( entityTypeID = arguments.entityTypeID, entityID = arguments.entityID )>

					<cfelse>

						<!--- already Existed --->
						<cfquery datasource="#variables.datasource#" name="local.qry">
							UPDATE ratings 
								SET rating = <cfqueryparam value="#arguments.rating#" cfsqltype="cf_sql_integer">,
									ratingDate = <cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">

								WHERE entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
									AND entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
									AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
						</cfquery>

						<cfset UpdateRecipeRating( entityTypeID = arguments.entityTypeID, entityID = arguments.entityID )>

					</cfif>

				<cfelse>
					<cfset result.message = application.messages['recipe_get_found_error']>
					<cfreturn nodata().withStatus(404) />
				</cfif>

			<cfelse>
				<cfset result.message = application.messages['recipe_get_found_error']>
				<cfreturn nodata().withStatus(404) />
			</cfif>
			
			<cfcatch>
				<cfset result.message = errorMessage( message = 'rating_post_add_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 355, extra = "method: /rating/POST", errorCatch = variables.cfcatch )>
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>

		</cftry>

		<cfset result.status  	= true />
		
		<cfset result.message = application.messages['rating_post_add_success']>

	  	<cfset logAction( actionID = 354, extra = "method: /rating/POST" )>

		<cfreturn noData().withStatus(200) />
	</cffunction>


	<cffunction name="GET" access="public" output="false" hint="User can like the item of entity">
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
							
					FROM ratings r 
					INNER JOIN val_entityType ve ON r.entityTypeID = ve.entityTypeID
					LEFT JOIN users u ON r.userID = u.userID

					<cfif structKeyExists( pkStruct, local.entityTypeQuery.entityTable ) >
						LEFT JOIN #local.entityTypeQuery.entityTable# en ON r.entityID = en.#pkStruct[local.entityTypeQuery.entityTable]#
					</cfif>
					
					WHERE r.entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
					AND r.entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
					AND r.userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
				</cfquery>

			<cfelse>

				<cfset result.message = application.messages['rating_get_found_error'] />
				<cfreturn noData().withStatus(404) />

			</cfif>

			<cfif result.query.recordCount EQ 0>

				<cfset result.message = application.messages['rating_get_found_error'] />
				<cfreturn noData().withStatus(404) />

			</cfif>

			<cfcatch>

				<cfset result.message = errorMessage( message = 'rating_post_add_error', error = variables.cfcatch) />
				<cfset logAction( actionID = 347, extra = "method: /rating/GET", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>

		<cfset result.status  	= true />
		<cfset result.message = errorMessage(message = 'rating_get_found_success') />

	  	<cfset logAction( actionID = 348, extra = "method: /rating/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="DELETE" access="public" output="false" hint="The user can remove rating, if user already provide rating for item of Entity." auth="true">
		<cfargument name="entityTypeID" type="numeric" required="yes" hint="ID of entity">
		<cfargument name="entityID" type="numeric" required="yes" hint="ID of entity's item.">
		<cfargument name="userID" type="numeric" required="yes" hint="User ID.">
		<cfargument name="auth_token" type="string" required="yes" hint="User authorization token (auth_token)">
		
		<cfset var local.qry = "" />
		<cfset result = structNew()>
		<cfset result['status'] = false>
		<cfset result['message'] = ''>

		<cftry>
			
			<cfquery datasource="#variables.datasource#" name="local.qry" result="isDeleted">
				DELETE FROM ratings 
					WHERE entityID = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer">
						AND entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
						AND userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
						LIMIT 1
			</cfquery>
			
			<cfcatch>
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 357, extra = "method: /rating/DELETE", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>

		</cftry>

		<cfset statusCode = ( isDeleted.recordCount GT 0 ) ? 200 : 404 >

		<cfif statusCode EQ 200 >
			<cfset UpdateRecipeRating( entityTypeID = arguments.entityTypeID, entityID = arguments.entityID )>
		</cfif>

		<cfset result['status']  	= true />
		<cfset result['message'] = statusCode EQ 200 ? application.messages['rating_delete_remove_success'] : application.messages['rating_delete_remove_error']/>

	  	<cfset logAction( actionID = 356, extra = "method: /rating/DELETE" )>

		<cfreturn representationOf(result).withStatus(statusCode) />
	</cffunction>


	<cffunction name="UpdateRecipeRating" access="private" output= "false" hint = "updating avg ratings in recipe">
		<cfargument name="entityTypeID" type="numeric" required="false" default="0">

		<cfquery name="local.entityTypeQuery" dbtype="query">
			SELECT entityTable FROM application.val_tables.val_entityType
				WHERE entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer" >
		</cfquery>

		<cfif local.entityTypeQuery.recordCount >
			<cfset pkStruct = {"items":["itemID",""], "images":["imageID",""], "blogs":["blogID","blogRating"], "users":["userID",""], "contests":["contestID",""], "recipes":["recipeID","recipeRating"]}>
		</cfif>

		<cfset local.qry = "">

		<cfquery name = "qry" datasource="#variables.datasource#">
			UPDATE #local.entityTypeQuery.entityTable# SET  #pkStruct[local.entityTypeQuery.entityTable][2]# = 
			(	
				SELECT avg(rating) FROM ratings 
				WHERE entityTypeID  = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
				AND entityID        = <cfqueryparam value="#arguments.entityID#"	 cfsqltype="cf_sql_integer">
			) 
			WHERE #pkStruct[local.entityTypeQuery.entityTable][1]# = <cfqueryparam value="#arguments.entityID#" cfsqltype="cf_sql_integer"> 
		</cfquery>

	</cffunction>

</cfcomponent>