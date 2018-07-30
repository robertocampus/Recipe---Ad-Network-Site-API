<cfcomponent extends="taffyAPI.base" taffy:uri="/instagramAuth/" hint="get instagram authentication.">

	<cffunction name="GET" access="public" output="false" hint="Used to get accessToken from the server side.">
		<cfargument name="token" required="true" type="string" >		

		<cfset result = structNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>

        <cftry>

        	<cfhttp method="GET" result="userDetails" url="https://api.instagram.com/v1/users/self">
        		<cfhttpparam type="url" name="access_token"	   	value="#arguments.token#">        		
        	</cfhttp>

        	<cfif userDetails.status_code>
        	
        		<cfset result.dataset = deserializeJSON(userDetails.filecontent) >

        	<cfelse>

        		<cfreturn representationOf(result).withStatus(404) />

        	</cfif>
        	
		
			<cfcatch>
				<cfset result.message =errorMessage( message = 'socialinstagramauth_get_found_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1007, extra = "method: /instagramAuth/GET", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
		
		</cftry>			 

		<cfset result.status = true />
		<cfset result.message = application.messages['socialinstagramauth_get_found_success'] />

	  	<cfset logAction( actionID = 1005, extra = "method: /instagramAuth/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="POST" access="public" output="false" hint="get twitter user's deatail with these arguments.">
		<cfargument name="client_id" 		required="true" type="string" >
		<cfargument name="client_secret" 	required="true" type="string" >
		<cfargument name="grant_type" 		required="true" type="string" >
		<cfargument name="redirect_uri" 	required="true" type="string" >
		<cfargument name="code" 			required="true" type="string" >

		<cfset result = structNew() />
		<cfset result.status = false />

        <cftry>
        	
        	<cfhttp method="post" result="Authentication" url="https://api.instagram.com/oauth/access_token">
        		<cfhttpparam type="formfield" name="client_id"	   	value="#arguments.client_id#">
        		<cfhttpparam type="formfield" name="client_secret" 	value="#arguments.client_secret#">
        		<cfhttpparam type="formfield" name="grant_type" 	value="#arguments.grant_type#">
        		<cfhttpparam type="formfield" name="redirect_uri" 	value="#arguments.redirect_uri#">
        		<cfhttpparam type="formfield" name="code" 			value="#arguments.code#">
        	</cfhttp>

        	<cfif Authentication.status_code>
        	
        		<cfset result.dataset = deserializeJSON(Authentication.filecontent) >

        	<cfelse>

        		<cfset result.message = application.messages['socialinstagramauth_post_add_error']/>
        		<cfreturn representationOf(result).withStatus(404) />

        	</cfif>
		
			<cfcatch>

				<cfset result.message = errorMessage(message = 'socialinstagramauth_post_add_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1008, extra = "method: /instagramAuth/POST", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
		</cftry>			 

		<cfset result.status = true />
		<cfset result.message = application.messages['socialinstagramauth_post_add_success'] />

	  	<cfset logAction( actionID = 1007, extra = "method: /instagramAuth/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>