<cfcomponent extends="taffyAPI.base" taffy:uri="/instagram/" hint="Inserting social Login Details for instagram">

	<cffunction name="POST" access="public" returntype="Struct" output="true" hint = "can create social data using POST">
		
		<cfargument name="instagramUserID" 		required="true" 	type="string">
		<cfargument name="username" 			required="true" 	type="string">
		<cfargument name="bio" 					required="false" 	type="string"  	default="">
		<cfargument name="website" 				required="false" 	type="string"  	default="">
		<cfargument name="profile_picture" 		required="false" 	type="string"  	default="">
		<cfargument name="full_name" 			required="false" 	type="string"  	default="">
		<cfargument name="count_media" 			required="false" 	type="numeric" 	default="0">
		<cfargument name="count_followed_by" 	required="false" 	type="numeric" 	default="0">
		<cfargument name="count_follows" 		required="false"	type="numeric" 	default="0">
		<cfargument name="access_token" 		required="true" 	type="string">
		<cfargument name="access_token_secret" 	required="false" 	type="string" 	default="">
		<cfargument name="connectedStatus" 		required="false" 	type="numeric" default="1">
		
		<cfset result = structNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>
		<cftry>
			
			<cfquery name="local.query" datasource="#variables.datasource#" result="qry">
				INSERT INTO social_login_instagram (
														instagramUserID,
														username,
														bio,
														website,
														profile_picture,
														full_name,
														count_media,
														count_followed_by,
														count_follows,
														access_token,
														access_token_secret,
														connectedStatus
													)
				VALUES (
							<cfqueryparam value="#arguments.instagramUserID#"		cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.username#" 				cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.bio#" 					cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.website#" 				cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.profile_picture#" 		cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.full_name#" 			cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.count_media#" 			cfsqltype="cf_sql_numeric">,
							<cfqueryparam value="#arguments.count_followed_by#" 	cfsqltype="cf_sql_numeric">,
							<cfqueryparam value="#arguments.count_follows#" 		cfsqltype="cf_sql_numeric">,
							<cfqueryparam value="#arguments.access_token#" 			cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.access_token_secret#" 	cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.connectedStatus#" 		cfsqltype="cf_sql_bit">
						)
			</cfquery>

			<cfquery name="result.query" datasource="#variables.datasource#">
				SELECT * FROM social_login_instagram WHERE 
				instagramID = <cfqueryparam value="#qry.GENERATED_KEY#" cfsqltype="cf_sql_integer"> 
			</cfquery>
			
			<cfcatch>

				<cfset result.message = errorMessage( message = 'socialinstagram_post_add_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1002, extra = "method: /instagram/POST", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>

		<cfset result['status'] = true>
		<cfset result['message'] = application.messages['socialinstagram_post_add_success']>

		<cfset logAction( actionID 	= 1001, extra = "method: /instagram/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="GET" access="public" returntype="Struct" output="true" hint ="the instagram user already exist or not">		
		<cfargument name='instagramUserID' type="numeric"  required="true">

		<cfset result = structNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>

		<cftry>

			<cfquery name="result.query" datasource="#variables.datasource#">
				SELECT u.userID, u.userName, u.userEmail, sli.* FROM users AS u 
					INNER JOIN social_login AS sl ON u.userID = sl.userID
					INNER JOIN social_login_instagram AS sli ON sl.socialLoginUserID = sli.instagramUserID
					INNER JOIN val_socialtype AS vs ON vs.socialTypeID = sl.socialLoginTypeID
						WHERE sli.instagramUserID = <cfqueryparam value="#arguments.instagramUserID#" cfsqltype="cf_sql_varchar">
							AND vs.socialTypeName = <cfqueryparam value="instagram" cfsqltype="cf_sql_varchar">
			</cfquery>
			
			<cfscript>
				
				if( result.query.recordcount ) {

					auth = application.accountObj.createAuthTokenForSocialLogin( userID = result.query.userID );

					result['userID'] = auth.userID;
					result['auth_token'] = auth.auth_token;
					result['session_Expiry'] = auth.session_Expiry;
				}

			</cfscript>

			<cfcatch>
				<cfset result.message = errorMessage( message = 'socialinstagram_get_found_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1004, extra = "method: /instagram/GET", errorCatch = variables.cfcatch )>
				
				<cfreturn noData().withStatus(500) />

			</cfcatch>

		</cftry>

		<cfset result['status']	   = true />
		<cfset result.message = application.messages['socialinstagram_get_found_success']>
		<cfset logAction( actionID = 1003, extra = "method: /instagram/GET" )>

		<cfreturn representationOf(result).withStatus(200)>

	</cffunction>

</cfcomponent>