<cfcomponent extends="taffyAPI.base" taffy:uri="/facebookAuth/" hint="get twitter authentication.">

	<cffunction name="GET" access="public" output="false" hint="Used to get the long life user access token.">
		<cfargument name="accessToken" type="string" required="true" hint="user accessToken got from the login" />

		<cfset result = structNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = '' />

        <cftry>        	
			<!--- http call to get the long life server Access Token --->
        	<cfhttp url="https://graph.facebook.com/oauth/access_token?grant_type=fb_exchange_token&client_id=#application.fbAppID#&client_secret=#application.fbAppSecret#&fb_exchange_token=#arguments.accessToken#" result="serverAccessToken">
			
			<cfif serverAccessToken.status_code NEQ 200>
				<cfset local.error = deserializeJSON(serverAccessToken.filecontent) >				
				<cfset result.message = local.error.error.message >
				<cfreturn representationOf(result).withStatus(406) />
			</cfif>

			<cfset result['AccessToken']  = listLast( listfirst(serverAccessToken.filecontent, '&' ), '=' ) />

			<cfset result['TokenValidUpTo'] = dateformat( dateAdd("d", 60, now()), 'mm/dd/yyyy' )/>		

			       	

			<cfcatch>

				<cfset result.message = errorMessage(message = 'socialfacebookauth_get_found_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1006, extra = "method: /facebookAuth/GET", errorCatch = variables.cfcatch )>
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
		</cftry>			 

		<cfset result.status = true />
		
		<cfset result.message = application.messages['socialfacebookauth_get_found_success']>

	  	<cfset logAction( actionID = 1005, extra = "method: /facebookAuth/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>