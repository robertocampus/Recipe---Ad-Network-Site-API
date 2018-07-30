<cfcomponent extends="taffyAPI.base" taffy:uri="/twitterAuth/" hint="get twitter authentication.">

	<cffunction name="GET" access="public" output="false" hint="get the auth_token, auth_token_secret, auth_verifier values after successfull login.">

		<cfset result = structNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>

        <cftry>
        	
        	<cfset result.authStruct = application.objMonkehTweet.getAuthorisation( callbackURL = application.twitterCallBack ) >
		
			<cfcatch>

				<cfset result.message = errorMessage(message = 'socialtwitterauth_get_found_error', error = variables.cfcatch) />
				<cfset logAction( actionID = 1006, extra = "method: /twitterAuth/GET", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
		</cftry>			 

		<cfset result.status = true />
		<cfset result.message = application.messages['socialtwitterauth_get_found_success'] />

	  	<cfset logAction( actionID = 1005, extra = "method: /twitterAuth/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="POST" access="public" output="false" hint="get twitter user's deatail with these arguments.">
		<cfargument name="auth_token" required="true" type="string" >
		<cfargument name="auth_token_secret" required="true" type="string" >
		<cfargument name="auth_verifier" required="true" type="string" >

		<cfset result = structNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>

        <cftry>
        	<!---  Getting User's Access Details --->
			<cfset returnData = application.objMonkehTweet.getAccessToken(
																			requestToken	= 	arguments.auth_token,
																			requestSecret	= 	arguments.auth_token_secret,
																			verifier		=	arguments.auth_verifier
																		)>

			<cfif returnData.success >
				 <!--- Getting Profile User Details  --->
				<cfset result.userData = application.objMonkehTweet.getUserDetails( user_id = returnData.user_id )>
			<cfelse>
				<cfreturn noData().withStatus(401) />
			</cfif>
		
			<cfcatch>
				<cfset result.message = errorMessage( message ='socialtwitterauth_post_add_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1008, extra = "method: /twitterAuth/POST", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
		
		</cftry>			 

		<cfset result.status = true />
		<cfset result.message = application.messages['socialtwitterauth_post_add_success'] />

	  	<cfset logAction( actionID = 1007, extra = "method: /twitterAuth/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>