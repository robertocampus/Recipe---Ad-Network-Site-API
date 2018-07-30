<!--- data returned by this component can be highly sensitive --->
<!--- all the methods in this component require user authentication --->

<cfcomponent extends="taffyAPI.base" taffy:uri="/publishersMeta/" hint="Publisher Meta Data. ie. AdUnits, etc.">

	<cffunction name="GET" access="public" returntype="struct" output="true" hint="Return Publisher Meta DATA" auth="true">
		<cfargument name="userID"  		type="numeric"  required="true" hint="User ID">
		<cfargument name="publisherID"  type="numeric"  required="false"  hint="Publisher ID">
		<cfargument name="blogID"  		type="numeric"  required="false"  hint="Blog ID">
		<cfargument name="query"  		type="string"   required="no"  default="1" hint="Return query in result">
		<cfargument name="auth_token"   type="string"   required="true"  hint="User authorization token (auth_token).">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['message'] = "" />
		<cfset result['status'] = false />
		
		<cftry>
 			<cfquery datasource="#variables.datasource#" name="local.query">
 				SELECT meta_key, meta_value, userID, blogID, publisherID
				FROM publishers_meta
				WHERE 1 = 1
				
					AND userID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#" list="true"> )
					
					<cfif structKeyExists( arguments, "publisherID" ) AND len( arguments.publisherID ) >
						AND publisherID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.publisherID#"> )
					</cfif>
					
					<cfif structKeyExists(arguments, "blogID") AND  len( arguments.blogID ) >
						AND blogID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#"> )
					</cfif>				
 				ORDER BY metaID ASC
 			</cfquery> 			
 			
 			<cfif local.query.recordCount EQ 0 >
 				<cfset result.message = application.messages['publishersMeta_get_found_error']>
 				<cfreturn noData().withStatus(404) />
 			</cfif>

 			<!--- CONVERT QUERT TO STRUCTURE --->
 			<cfset result.publishers_Meta = queryToStruct( query = local.query, keyCol = "meta_key", valueCol = "meta_value" ) >

 			<cfif arguments.query EQ 1>
				<cfset result.query = local.query>
			</cfif>
				
			<cfcatch>

				<cfset logAction( actionID = 661, extra = "method: publishersMeta/GET", errorCatch = variables.cfcatch  )>
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />	

			</cfcatch>
			
	    </cftry>

	    <cfset result.status  	= true />
	    <cfset result.message = application.messages['publishersMeta_get_found_success']/>

	   	<cfset logAction( actionID = 280, extra = "method: publishersMeta/GET"  )>	

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="POST" access="public" returntype="Struct" output="true" hint="insert the meta data under the user." auth="true" >
		<cfargument name="userID"  		type="numeric"  required="true" 		hint="User ID" >
		<cfargument name="blogID"  		type="numeric"  required="false"  		hint="Blog ID" >
		<cfargument name="publisherID"  type="numeric"  required="false"  		hint="Publisher ID" default="0" >
		<cfargument name="meta_key" 	type="string" 	required="false"	hint="key of meta value" >
		<cfargument name="meta_value" 	type="string" 	required="false"	hint="a meta value" >
		<cfargument name="auth_token"   type="string"  	required="true"  	hint="User authorization token (auth_token)." >

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['message'] = "" />
		<cfset result['status'] = false />

		<cftry>
			
			<cfquery datasource="#variables.datasource#" name="result.query" result="qry">
				INSERT INTO publishers_meta (
												userID,
												uid,
												blogID,
												publisherID,
												meta_key,
												meta_value
											)
				VALUES (
							<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_numeric">,
							<cfqueryparam value="#createUUID()#" cfsqltype="cf_sql_varchar">

							<cfif structKeyExists(arguments, "blogID") >
								,<cfqueryparam value="#arguments.blogID#" cfsqltype="cf_sql_numeric">
							</cfif>
							
							<cfif structKeyExists(arguments, "publisherID") >
								,<cfqueryparam value="#arguments.publisherID#" cfsqltype="cf_sql_integer">
							</cfif>

							<cfif structKeyExists(arguments, "meta_key") >
								,<cfqueryparam value="#arguments.meta_key#" cfsqltype="cf_sql_varchar">
							</cfif>

							<cfif structKeyExists(arguments, "meta_value") >
								,<cfqueryparam value="#arguments.meta_value#" cfsqltype="cf_sql_varchar">
							</cfif>
						)
			</cfquery>

			<cfquery name="result.query" datasource="#variables.datasource#">
				SELECT * FROM publishers_meta
				WHERE metaID = <cfqueryparam value="#qry.GENERATED_KEY#" cfsqltype="cf_sql_integer">
			</cfquery>

			<cfcatch>	

				<cfset logAction( actionID = 282, extra = "method: /publishersMeta/POST", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage(message = 'publishersMeta_post_add_error', error = variables.cfcatch) />
				<cfreturn noData().withStatus(500) />	

			</cfcatch>

		</cftry>

		<cfset result.status  	= true />
		<cfset result.message = application.messages['publishersMeta_post_add_success'] />

	  	<cfset logAction( actionID = 281, extra = "method: /publishersMeta/POST" )>

		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>



	<cffunction name="PUT" access="public" hint="Update Publisher Meta DATA" returntype="struct" output="true" auth="true">
		<cfargument name="publisherID"  type="string"  required="false" hint="Publisher ID">
		<cfargument name="userID"  		type="string"  required="true" hint="User ID">
		<cfargument name="blogID"  		type="string"  required="false"  hint="Blog ID">
		<cfargument name="key"  		type="string"  required="true" hint="Key to Update">
		<cfargument name="value"  		type="string"  required="true" hint="Value for Key">
		<cfargument name="auth_token"   type="string"  required="true" hint="users authentication token">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset var local = StructNew() />
		
		<cfset result['status'] = false />
		<cfset result['message'] = ''>

		<cftry>
		
			<cfquery datasource="#variables.datasource#" name="local.query">

				UPDATE publishers_meta
				   SET meta_value = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.value#">
				 WHERE meta_key = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.key#">
				
				AND userID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#"> )

				<cfif isDefined("arguments.publisherID")>
				AND publisherID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.publisherID#"> )
				</cfif>
				
				<cfif isDefined("arguments.blogID")>
				AND blogID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#"> )
				</cfif>
				
			</cfquery>
		
			<cfset result.status = true />
	

			<cfcatch>
				
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage(message = 'database_query_error')>
		
				<!--- // 284, Error while inserting publisher meta --->
				<cfset logAction( actionID = 284, extra = "method: getPublicUsers", errorCatch = variables.cfcatch  )>	
			  	<cfreturn representationOf(result.message).withStatus(404)>

			</cfcatch>
		
	   </cftry>

	   	<!--- 283:publisher meta inserted successfully --->
	   	<cfset result.message = application.messages['pupublishersMeta_put_update_success']>
	   	<cfset logAction( actionID = 283, extra = "method: getPublicUsers")>
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>	

</cfcomponent>