<cfcomponent extends="taffyAPI.base" taffy:uri="/activateAccount/" hint="used to Activate Publisher Account.">

	<cffunction name="PUT" access="public" hint="Activate Publisher Account" returntype="struct" output="true">
		<cfargument name="userConfirmationCode"		type="string" required="yes" hint="userConfirmationCode for activate the account">
  	
		<!--- :: init result structure --->	
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />
		<cfset result['status'] = false />
		<cfset result['message']=''>

		<cftry>
		
	 		<!--- // check if there is a current record with this UUID --->
			<cfquery datasource="#variables.datasource#" name="local.getUUID"> 

				SELECT userID,isConfirmed
				FROM users
				WHERE userConfirmationCode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userConfirmationCode#" maxlength="25">	
				LIMIT 1

			</cfquery>
			
			<!--- // START: check if an active UUID is present --->
			<cfif local.getUUID.recordCount EQ 0>
				<!---// User : Acivated - Error",	"Not Found, The UUID is either not found or already activated --->
				<cfset result.message = application.messages['activateAccount_put_activate_error']>
				<!--- // 8201, Activate Account: Not Found, The UUID is either not found or already activated, 1 --->
				<cfset logAction( actionID = 8201,extra = "method: /activateAccount/PUT")>	
				<cfreturn representationOf(result).withStatus(404)>

			<cfelse>
				<cfif local.getUUID.isConfirmed EQ 0>
					
					<!--- generate new password --->
					<cfset local.pwd = left(replace(CreateUUID(), "-", ""), 7) >
				
					<!--- // update user publisher active status --->
		 			<cfquery datasource="#variables.datasource#" name="local.query">

						UPDATE users 
						SET isConfirmed = <cfqueryparam value="1" cfsqltype="cf_sql_integer">, 
						userDateConfirmed =  <cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#"  cfsqltype="cf_sql_timestamp" >,
						userPassword = <cfqueryparam value="#local.pwd#" cfsqltype="cf_sql_varchar" >
						WHERE userID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#local.getUUID.userID#">
						 	AND userConfirmationCode = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userConfirmationCode#" maxlength="25">

					</cfquery>				
				
					<!--- // 8200, Activate Account:Success, The Publisher acount was activated successfully., 1--->
					<cfset logAction( actionID = 8200, extra = "method: /activateAccount/PUT")>	
					 				
					<cfset result.userID = local.getUUID.userID />
					<cfset result.message = application.messages['activateAccount_put_activate_success']>						
					<cfset result['alreadyActivated'] = 0>
				<cfelse>
					<cfset result['alreadyActivated'] = 1>

				</cfif>
				<!--- // Your account has been activated	 				 --->
				<cfset result.status = true />

			<!--- // END: check if an active UUID is present --->
			</cfif>   	
	
		
  		
			<cfcatch> 
				
				<!--- // 8203, Activate Account: Error, Error encountered while activating account, 1 --->
				<cfset logAction( actionID = 8203, extra = "method: /activateAccount/PUT", errorCatch = variables.cfcatch)>	
				<cfset result.message = errorMessage(message='database_query_error', error = variables.cfcatch)>
				<cfreturn representationof( result.message ).withStatus(500)>

			</cfcatch> 
		
		</cftry>
		
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>