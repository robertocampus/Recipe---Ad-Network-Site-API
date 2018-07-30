<cfcomponent extends="taffyAPI.base" taffy:uri="/madeIt/" hint="Used to GET recipe made it data from recipe_madeit table.">

	<cffunction name="GET" returntype="Struct" access="public" hint="Import recipes details form users wordpress blog" output="false" auth="true">

		<cfargument name="userID" type="numeric" required="true" hint="userID of who made it">
		<cfargument name="auth_token" type="string" required="true" hint="auth_token of the user">
		<cfargument name="recipeID" type="numeric" required="false" default="0" hint="recipeID of user what he made it">
		

		<cfset result = structNew()>
		<cfset result['message'] = '' >
		<cfset result['status']  = false >

		<cftry>

			<cfquery name="result.query" datasource="#variables.dataSource#"> 
				
				SELECT * FROM recipe_madeit 
					WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">

					<cfif structKeyExists(arguments,'recipeID') AND arguments.recipeID NEQ 0>
						
						AND recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

					</cfif>
					AND madeitStatus = 1

			</cfquery>

			<cfif result.query.recordCount EQ 0>

				<cfset result.message = application.messages['madeit_get_found_error']>

				<!--- // 9011, 'error:made it record not found ', 1 --->
				<cfset logAction( actionID = 9011, extra = "method: /madeit/GET"  )>
				<cfreturn noData().withStatus(404)>

			</cfif>
			
			<cfset result.message = application.messages['madeit_get_found_success']>
			<cfset result.status 	= 'true' >

			<!--- // 9010, 'success:made it record found', 1 --->
			<cfset logAction( actionID = 9010, extra = "method: /madeit/GET" )>
			<cfreturn representationOf(result).withStatus(200)>

			<cfcatch>

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /madeit/GET", errorCatch = variables.cfcatch )>
	  			<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>

				<cfreturn representationOf(result.messages).withStatus(500) />

			</cfcatch>

		</cftry>

	</cffunction>


	<cffunction name="POST" returntype="Struct" access="public" output="false" auth="true" hint="to add new madeit record for a user">
		
		<cfargument name="userID" type="numeric" required="true" hint="userID of who made it">
		<cfargument name="auth_token" type="string" required="true" hint="auth_token of the user">
		<cfargument name="recipeID" type="numeric" required="true" hint="recipeID of user what he made it">
		<cfargument name="madeitStatus" type="numeric" required="true" hint="value 1 user made the recipe">

		<cfset result = structNew() >
		<cfset result['message'] = '' >
		<cfset result['status']  = false >		

		<cftry>

			<cfquery name="local.query" datasource="#variables.dataSource#">
				SELECT * FROM recipe_madeit 
					WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
						AND recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">  
			</cfquery>

			<cfif local.query.recordCount NEQ 0 AND local.query.madeitStatus EQ arguments.madeitStatus>

				<cfset status = ( arguments.madeitStatus EQ 1?'as I made it':'as not made it' ) >

				<cfset result.message = 'You have already marked this recipe #status#'>
				<cfreturn representationOf(result).withStatus(200)>


			<cfelseif local.query.recordCount NEQ 0 AND local.query.madeitStatus NEQ arguments.madeitStatus>

				<cfquery name="local.query" datasource="#variables.dataSource#">
					
					UPDATE recipe_madeit SET 
						madeitStatus = <cfqueryparam value="#arguments.madeitStatus#" cfsqltype="cf_sql_integer">,
						madeitDate   = <cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">
							WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">
							AND	  userID   = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">

				</cfquery>

				<cfset status = ( arguments.madeitStatus EQ 1 ? application.messages['madeit_post_add_success'] : application.messages['madeit_post_remove_success'] )>

				<cfset result.message 	= status >
				<cfset result.status 	= true >				

				<!--- // 9014, 'success:made it record has been updated, 1 --->
				<cfset logAction( actionID = 9014, extra = "method: /madeit/POST"  )>
				<cfreturn representationOf(result).withStatus(200)>

			</cfif>

			<cfquery name="local.query" datasource="#variables.dataSource#" result="qry"> 

				INSERT INTO recipe_madeit (
											userID,
											recipeID,
											madeitStatus,
											madeitDate
										) 
								VALUES(
										<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">,
										<cfqueryparam value="#arguments.recipeId#" cfsqltype="cf_sql_integer">,
										<cfqueryparam value="#arguments.madeitStatus#" cfsqltype="cf_sql_integer">,
										<cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">
									)
		
			</cfquery>

				<cfset result.id = qry.GENERATED_KEY >

			<cfcatch>	

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset result.message =errorMessage( message = 'database_query_error', error = variables.cfcatch )>
				<cfset logAction( actionID = 661, extra = "method: /madeit/POST")>				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>

		<cfset result.status 	= true >
		<cfset result.message = application.messages['madeit_post_add_success']>

		<!--- // 9012, 'success:madeit record has been added, 1 --->
		<cfset logAction( actionID = 9012, extra = "method: /madeit/POST"  )>
		<cfreturn representationOf(result).withStatus(200)>

	</cffunction>


</cfcomponent>