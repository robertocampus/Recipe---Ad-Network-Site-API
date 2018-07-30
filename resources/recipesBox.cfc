<cfcomponent extends="taffyAPI.base" taffy:uri="/recipesBox/{recipeBoxID}" hint="Using this user can able to <code>Get</code> a single recipe details by passing recipeID. Can also able to <code>Update</code> & <code>Delete</code> an existing recipe using recipeID.">

	<cffunction name="GET" access="public" hint="<code>GET</code> a single recipesBox details data using RecipesBoxID" output="false" auth="true">
		<cfargument name="recipeBoxID" 	  	  type="numeric" required="true"  hint="Recipe ID (Numeric)">
		<cfargument name="userID" 	  type="numeric" required="true"  hint="Current Session UserID.">
		<cfargument name="auth_token" type="string"  required="true"  hint="User authorization token.">

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />
  
		<cftry>			

			<cfquery datasource="#variables.datasource#" name="result.query" >
				
				SELECT 	r.recipeTitle,
						r.recipeID						
					FROM recipe_box AS rbx
						LEFT JOIN recipes_boxes AS r_map ON rbx.recipeBoxID = r_map.recipeBoxID
						LEFT JOIN recipes AS r ON r_map.recipeID = r.recipeID
					WHERE rbx.recipeBoxID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeBoxID#">
					AND rbx.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
					
			</cfquery>

			<cfif result.query.recordCount EQ 0 >
				<cfset result.message = application.messages['recipesbox_get_found_error']>
				<cfreturn noData().withStatus(404) />
				
			</cfif>

			<cfcatch>

				<cfset result.message = errorMessage( query = 'database_query_error', error = variables.cfcatch)>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipesBox/{recipeBoxID}/GET", errorCatch = variables.cfcatch )>	

			  	<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
			
		</cftry>

		<cfset result.status  = true />
		<cfset result.message = application.messages['recipesbox_get_found_success']/>

	  	<cfset logAction( actionID = 2105, extra = "method: /recipesBox/{recipeBoxID}/GET" )>

		<cfreturn representationOf(result).withStatus(200) />
		
	</cffunction>

	<cffunction name="PUT" access="public" hint="<code>UPDATE</code> a single recipesBox details data using RecipesBoxID" output="false" auth="true">
		<cfargument name="recipeBoxID" 	  	  	 type="numeric" required="true"   hint="RecipeBoxID (Numeric)">
		<cfargument name="recipeBoxName" type="string"  required="false"  hint="Name of the recipeBox.">
		<cfargument name="orderID" 		 type="numeric" required="false"  hint="Display order of the recipeBox.">
		<cfargument name="active" 		 type="numeric" required="false"  hint="Current Status of the recipeBox.">
		<cfargument name="userID" 	     type="numeric" required="true"   hint="Current Session UserID.">
		<cfargument name="auth_token"    type="string"  required="true"   hint="User authorization token.">

		<cftry>

			<cfset var result = StructNew() />
			<cfset result['status']  = false />
			<cfset result['message'] = "" />
			
			<cfquery datasource="#variables.datasource#" name="result.query" result="isUpdated">
				
				UPDATE recipe_box
					SET recipeBoxID = recipeBoxID
						<cfif structKeyExists(arguments,"recipeBoxName") AND len(arguments.recipeBoxName)>
							,recipeBoxName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeBoxName#" />
						</cfif>
						<cfif structKeyExists(arguments,"orderID") AND len(arguments.orderID)>
							,orderID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.orderID#" />
						</cfif>
						<cfif structKeyExists(arguments,"active") AND len(arguments.active)>
							,active = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.active#" />
						</cfif>

						,recipeBoxUpdateDate = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >
					WHERE
						recipeBoxID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeBoxID#">
						AND userID  = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">

			</cfquery>

			<cfcatch>
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>	
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipesBox/{recipeBoxID}/PUT", errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.mesage).withStatus(500) />

			</cfcatch>

		</cftry>

		<cfset statusCode = ( isUpdated.recordCount GT 0 ) ? 200 : 404 >

		<cfset result.status  = true />
		<cfset result.message = ( isUpdated.recordCount GT 0 ) ? application.messages['recipesbox_put_update_success'] : application.messages['recipesbox_put_update_error'] />

	  	<cfset logAction( actionID = 2103, extra = "method: /recipesBox/{recipeBoxID}/PUT" )>
		
		<cfreturn representationOf(result).withStatus(statusCode) />
		
	</cffunction>

	<cffunction name="DELETE" access="public" hint="<code>DELETE</code> a single recipesBox details data using RecipesBoxID" output="false" auth="true">
		<cfargument name="recipeBoxID" 	  	  type="numeric" required="true"  hint="Recipe ID (Numeric)">
		<cfargument name="userID" 	  type="numeric" required="true"  hint="Current Session UserID.">
		<cfargument name="auth_token" type="string"  required="true"  hint="User authorization token.">

			<cftry>

				<cfset var result = StructNew() />
				<cfset result['status']  = false />
				<cfset result['message'] = "" />

				<cfquery datasource="#variables.datasource#" name="local.query" result="isDeleted">

					DELETE FROM recipe_box
						WHERE recipeBoxID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeBoxID#">
						AND userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">

				</cfquery>

				<cfif isDeleted.recordCount NEQ 0>
					
					<cfquery datasource="#variables.datasource#" name="local.queryData">
						DELETE FROM recipes_boxes
							WHERE recipeBoxID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeBoxID#">
					</cfquery>

				</cfif>


				<cfcatch>

					<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
					<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
					<cfset logAction( actionID = 661, extra = "method: /recipesBox/{recipeBoxID}/DELETE", errorCatch = variables.cfcatch )>

					<cfreturn representationOf( result.message ).withStatus(500) />

				</cfcatch>

			</cftry>

			<cfset statusCode = ( isDeleted.recordCount GT 0 ) ? 200 : 404 >

			<cfset result.status  = true />
			<cfset result.message = ( isDeleted.recordCount GT 0 ) ? application.messages['recipesbox_delete_remove_success'] : application.messages['recipesbox_delete_remove_error'] />

		  	<cfset logAction( actionID = 2106, extra = "method: /recipesBox/{recipeBoxID}/DELETE" )>

			<cfreturn representationOf(result).withStatus(statusCode) />

	</cffunction>

</cfcomponent>