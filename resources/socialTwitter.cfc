<cfcomponent extends="taffyAPI.base" taffy:uri="/twitter/" hint="Inserting social Login Details for twitter">

	<cffunction name="POST" access="public" output="false" hint="can create Social DATA using <code>POST</code>">
		<cfargument name="twitterUserID"   		required="yes"  type="numeric" default="" />
        <cfargument name="name"		        	required="yes"  type="string"  default="" />
        <cfargument name="screen_name"			required="yes"  type="string"  default="" />
        <cfargument name="location"    			required="no"   type="string"  default="" />
        <cfargument name="profile_location" 	required="no"   type="string"  default="" />
        <cfargument name="description"      	required="no"   type="string"  default="" />
        <cfargument name="url"       			required="no"   type="string"  default="" />
        <cfargument name="followers_count"  	required="no"   type="numeric" default="0" />
        <cfargument name="friends_count" 		required="no"   type="numeric" default="0" />
        <cfargument name="listed_count"     	required="no"   type="numeric" default="0" />
        <cfargument name="favourites_count" 	required="no"   type="numeric" default="0" />
        <cfargument name="statuses_count" 		required="no"   type="numeric" default="0" />
        <cfargument name="created_at" 			required="no"   type="string"  default="" />
        <cfargument name="utc_offset" 			required="no"   type="string"  default="" />
        <cfargument name="time_zone" 			required="no"   type="string"  default="" />
        <cfargument name="profile_image_url"	required="no"   type="string"  default="" />
        <cfargument name="access_token" 		required="no"   type="string"  default="" />
        <cfargument name="access_token_secret"  required="yes"  type="string"  default="" />        
        <cfargument name="connectedStatus"  	required="no"  	type="string"  default="1" />        

        <cfset result = structNew() />
        <cfset result['status'] = false />
        <cfset result['message'] = ''>

        <cftry>

	        <cfquery name="local.query" datasource="#variables.datasource#" result="qry">
	            INSERT INTO social_login_twitter (
	                                                twitterUserID,
													name,
													screen_name,
													location,
													profile_location,
													description,
													url,
													followers_count,
													friends_count,
													listed_count,
													favourites_count,
													statuses_count,
													created_at,
													utc_offset,
													time_zone,
													profile_image_url,
													access_token,
													access_token_secret,
													connectedStatus
	                                                )
	            VALUES (
	                        <cfqueryparam value="#arguments.twitterUserID#" 		cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.name#" 					cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.screen_name#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.location#" 				cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.profile_location#" 		cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.description#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.url#" 					cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.followers_count#" 		cfsqltype="cf_sql_numeric">,
	                        <cfqueryparam value="#arguments.friends_count#" 		cfsqltype="cf_sql_numeric">,
	                        <cfqueryparam value="#arguments.listed_count#" 			cfsqltype="cf_sql_numeric">,
	                        <cfqueryparam value="#arguments.favourites_count#" 		cfsqltype="cf_sql_numeric">,
	                        <cfqueryparam value="#arguments.statuses_count#" 		cfsqltype="cf_sql_numeric">,
	                        <cfqueryparam value="#arguments.created_at#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.utc_offset#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.time_zone#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.profile_image_url#" 	cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.access_token#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.access_token_secret#" 	cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.connectedStatus#" 		cfsqltype="cf_sql_bit">
	                    )
	        </cfquery>

	        <cfquery name="result.query" datasource="#variables.datasource#">
				SELECT * FROM social_login_twitter
				WHERE twitterID = <cfqueryparam value="#qry.GENERATED_KEY#" cfsqltype="cf_sql_integer">
			</cfquery>

			<cfcatch>

				<cfset result.message =errorMessage(message = 'socialtwitter_post_add_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1002, extra = "method: /twitter/POST", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
		</cftry>
			 
		<cfset result['status'] = true />
		<cfset result['message'] = application.messages['socialtwitter_post_add_success'] />

	  	<cfset logAction( actionID = 1001, extra = "method: /twitter/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="GET" access="public" returntype="Struct" output="true" hint="the twitter user already exist or not">
		<cfargument name="twitterUserID" type="numeric" required="yes" hint="twitter user id who login via twitter.">

		<cfset result = structNew() />
		<cfset result['status'] = false />

		<cftry>

			<cfquery datasource="#variables.datasource#" name="result.query">
				SELECT u.userID, u.userName, u.userEmail, slt.* FROM users AS u
					INNER JOIN social_login AS sl ON u.userID = sl.userID
					INNER JOIN social_login_twitter AS slt ON sl.socialLoginUserID = slt.twitterUserID
					INNER JOIN val_socialtype AS vs ON vs.socialTypeID = sl.socialLoginTypeID
						WHERE slt.twitterUserID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.twitterUserID#">
							AND vs.socialTypeName = <cfqueryparam cfsqltype="cf_sql_varchar" value="twitter">
			</cfquery>

			<cfscript>
				if( result.query.recordCount ) {
					auth = application.accountObj.createAuthTokenForSocialLogin( userID = result.query.userid );

					result['userid'] = auth.userID;
					result['auth_token'] = auth.auth_token;
					result['session_Expiry'] = auth.session_Expiry;
				}
			</cfscript>

			<cfcatch>

				<cfset result.message = errorMessage( message = 'socialtwitter_get_found_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1004, extra = "method: /twitter/GET", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>

		</cftry>
		
		<cfset result['status'] = true />
		<cfset result['message'] = application.messages['socialtwitter_get_found_success']>
		<cfset logAction( actionID = 1003, extra = "method: /twitter/GET" )>

		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>

</cfcomponent>