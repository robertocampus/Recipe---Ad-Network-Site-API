<cfcomponent extends="taffyAPI.base" taffy:uri="/pinterest/" hint="Inserting social Login Details for pinterest">

	<cffunction name="POST" access="public" output="false" hint="can create Social DATA using <code>POST</code>">
		<cfargument name="pinterestUserID"   	required="yes"  type="numeric" default="" />
        <cfargument name="username"	        	required="yes"  type="string"  default="" />
        <cfargument name="first_name"			required="yes"  type="string"  default="" />
        <cfargument name="last_name"   			required="no"   type="string"  default="" />
        <cfargument name="bio"				 	required="no"   type="string"  default="" />
        <cfargument name="pins_count"  			required="no"   type="numeric" default="0" />
        <cfargument name="following_count" 		required="no"   type="numeric" default="0" />
        <cfargument name="followers_count"     	required="no"   type="numeric" default="0" />        
        <cfargument name="boards_count" 		required="no"   type="numeric" default="0" />
        <cfargument name="likes_count" 			required="no"   type="numeric" default="0" />
        <cfargument name="profile_image_url"	required="no"   type="string"  default="" />
        <cfargument name="access_token" 		required="no"   type="string"  default="" />
        <cfargument name="connectedStatus"  	required="no"  	type="string"  default="1" />        

        <cfset result = structNew() />
        <cfset result['status'] = false />
        <cfset result['message'] = ''>

        <cftry>

	        <cfquery name="local.query" datasource="#variables.datasource#" result="qry">
	            INSERT INTO social_login_pinterest (
	                                                pinterestUserID,
													username,
													first_name,
													last_name,
													bio,
													pins_count,
													following_count,
													followers_count,
													boards_count,
													likes_count,
													profile_image_url,
													access_token,
													connectedStatus
	                                                )
	            VALUES (
	                        <cfqueryparam value="#arguments.pinterestUserID#" 		cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.username#" 				cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.first_name#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.last_name#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.bio#" 					cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.pins_count#" 			cfsqltype="cf_sql_numeric">,
	                        <cfqueryparam value="#arguments.following_count#" 		cfsqltype="cf_sql_numeric">,
	                        <cfqueryparam value="#arguments.followers_count#" 		cfsqltype="cf_sql_numeric">,
	                        <cfqueryparam value="#arguments.boards_count#" 			cfsqltype="cf_sql_numeric">,
	                        <cfqueryparam value="#arguments.likes_count#" 			cfsqltype="cf_sql_numeric">,
	                        <cfqueryparam value="#arguments.profile_image_url#" 	cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.access_token#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.connectedStatus#" 		cfsqltype="cf_sql_bit">
	                    )
	        </cfquery>

	        <cfquery name="result.query" datasource="#variables.datasource#">
				SELECT * FROM social_login_pinterest
				WHERE pinterestID = <cfqueryparam value="#qry.GENERATED_KEY#" cfsqltype="cf_sql_integer">
			</cfquery>

			<cfcatch>

				<cfset result.message =errorMessage(message = 'socialfacebook_post_add_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1002, extra = "method: /pinterest/POST", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
		</cftry>
			 
		<cfset result['status'] = true />
		<cfset result['message'] = application.messages['socialpinterest_post_add_success'] />

	  	<cfset logAction( actionID = 1001, extra = "method: /pinterest/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="GET" access="public" returntype="Struct" output="true" hint="the pinterest user already exist or not">
		<cfargument name="pinterestUserID" type="numeric" required="yes" hint="pinterest user id who login via pinterest.">

		<cfset result = structNew() />
		<cfset result['status'] = false />

		<cftry>

			<cfquery datasource="#variables.datasource#" name="result.query">
				SELECT u.userID, u.userName, u.userEmail, slp.* FROM users AS u
					INNER JOIN social_login AS sl ON u.userID = sl.userID
					INNER JOIN social_login_pinterest AS slp ON sl.socialLoginUserID = slp.pinterestUserID
					INNER JOIN val_socialtype AS vs ON vs.socialTypeID = sl.socialLoginTypeID
						WHERE slp.pinterestUserID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.pinterestUserID#">
							AND vs.socialTypeName = <cfqueryparam cfsqltype="cf_sql_varchar" value="pinterest">
			</cfquery>

			<cfscript>
				if( result.query.recordCount ) {
					auth = application.accountObj.createAuthTokenForSocialLogin( userID = result.query.userid );

					result['userid'] = auth.userID;
					result['auth_token'] = auth.auth_token;
					result['session_Expiry'] = auth.session_Expiry;
				} else {

					result['status'] = false;					
					result['message'] = application.messages['socialpinterest_get_Not_found'];
					logAction( actionID = 1003, extra = "method: /pinterest/GET" );

					return representationOf(result).withStatus(200);

				}
			</cfscript>

			<cfcatch>

				<cfset result.message = errorMessage( message = 'socialpinterest_get_found_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1004, extra = "method: /pinterest/GET", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>
		
		<cfset result['status'] = true />
		<cfset result['message'] = application.messages['socialpinterest_get_found_success']>
		<cfset logAction( actionID = 1003, extra = "method: /pinterest/GET" )>

		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>

</cfcomponent>