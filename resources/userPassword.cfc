<cfcomponent extends="taffyAPI.base" taffy:uri="/userPassword" hint="User used to get status of user password.">
	
	<cffunction name="GET" access="public" hint="Return User Password Status" returntype="struct" output="false" auth="true">
		<cfargument name="userID"  		type="numeric" 	required="yes"	hint="Email address to search for">		
		<cfargument name="auth_token"   type="string"   required="yes"  hint="User authorization token (auth_token)" />
	 	
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />
		<cftry>
		
	        <cfquery datasource="#variables.datasource#" name="local.query">
 				SELECT 
 					u.userName,
					u.userFirstName,
					u.userLastName,
					u.userEmail,
					u.userPassword
				FROM users u INNER JOIN social_login sl ON u.userID = sl.userID AND sl.isMainAccount = 1
				WHERE sl.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				LIMIT 0,1							
			</cfquery>

			<cfquery dbtype="query" name="result.query" >
 				SELECT 
					userName,
					userFirstName,
					userLastName,
					userEmail
				FROM local.query
			</cfquery>

			<cfif local.query.recordCount NEQ 0 >				
				
				<cfif local.query.userPassword EQ '' >
					<cfset result.isPasswordNotSet  = 1 >
				<cfelse>
					<cfset result.isPasswordNotSet  = 0 >
				</cfif>

				 <cfset result.message = application.messages['userPassword_get_found_success'] />

			<cfelse>

				<cfset result.isPasswordNotSet  = 0 >
				<cfset result.message = application.messages['userPassword_not_found_success'] />

			</cfif>

			<cfcatch>				
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /userPassword GET", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>

	    </cftry>

	    <cfset result.status = true />
	  	<cfset logAction( actionID = 101, extra = "method: /userPassword GET" )>
 		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>