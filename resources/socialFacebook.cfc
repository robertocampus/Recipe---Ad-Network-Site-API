<cfcomponent extends="taffyAPI.base" taffy:uri="/facebook/" hint="Inserting social Login Details for FaceBook">

	<cffunction name="POST" access="public" output="true" returntype="Struct" hint="can create Social DATA using <code>POST</code>">
		<cfargument name="facebookUserID" 		required="yes"  type="string" 	default="" />
        <cfargument name="email"        		required="yes"  type="string"  	default="" />
        <cfargument name="first_name"   		required="no"   type="string"  	default="" />
        <cfargument name="last_name"    		required="no"   type="string"  	default="" />
        <cfargument name="gender"       		required="no"   type="string"  	default="" />
        <cfargument name="link"         		required="no"   type="string"  	default="" />
        <cfargument name="locale"       		required="no"   type="string"  	default="" />
        <cfargument name="timezone"     		required="no"   type="string"  	default="" />
        <cfargument name="updated_time" 		required="no"   type="string"  	default="" />
        <cfargument name="verified"     		required="no"   type="string"  	default="" />
        <cfargument name="access_token" 		required="yes"  type="string"  	default="" />
        <cfargument name="profile_image_url" 	required="no"  	type="string" 	default="" />
        <cfargument name="expiry_time" 			required="no"  	type="string" 	default="" />
        <cfargument name="connectedStatus" 		required="no"  	type="numeric" 	default="1" />

        <cfset result = structNew() />
        <cfset result['status'] = false />
        <cfset result['message'] = ''>
        <cftry>

	        <cfquery name="local.query" datasource="#variables.datasource#" result="qry">
	            INSERT INTO social_login_facebook (
	                                                facebookUserID,
	                                                email,
	                                                first_name,
	                                                last_name,
	                                                gender,
	                                                link,
	                                                locale,
	                                                timezone,
	                                                updated_time,
	                                                verified,
	                                                access_token,
	                                                profile_image_url,
	                                                expiry_time,
	                                                connectedStatus
	                                               )
	            VALUES (
	                        <cfqueryparam value="#arguments.facebookUserID#"	cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.email#" 		 	cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.first_name#" 		cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.last_name#" 		cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.gender#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.link#" 				cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.locale#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.timezone#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.updated_time#" 		cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.verified#" 			cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.access_token#" 		cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.profile_image_url#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.expiry_time#" 		cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.connectedStatus#" 	cfsqltype="cf_sql_bit">	                        

	                    )
	        </cfquery>

	        <cfquery name="result.query" datasource="#variables.datasource#">
				SELECT * FROM social_login_facebook
				WHERE facebookID = <cfqueryparam value="#qry.GENERATED_KEY#" cfsqltype="cf_sql_integer">
			</cfquery>

			<cfcatch>

				<cfset result.message = errorMessage( message = 'socialfacebook_post_add_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1006, extra = "method: /socialFacebook/POST", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
		</cftry>
			 
		<cfset result['status'] = true />
		<cfset result.message = application.messages['socialfacebook_post_add_success'] />

	  	<cfset logAction( actionID = 1005, extra = "method: /socialFacebook/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="GET" access="public" returntype="Struct" output="true" hint="to check the facebook user already registered or new one.">
		<cfargument name="facebookUserID" required="true" type="numeric" hint="FaceBook ID">

		<cfset result = structNew() />
        <cfset result['status'] = false />
        <cfset result['messages'] = ''>

        <cftry>
        	
        	<cfquery datasource="#variables.datasource#" name="result.query">
        		SELECT slf.*, u.userID, u.userName, u.userEmail FROM users AS u 
					INNER JOIN social_login AS sl ON u.userID = sl.userID
					INNER JOIN social_login_facebook AS slf ON sl.socialLoginUserID = slf.facebookUserID
					INNER JOIN val_socialtype AS vs ON vs.socialTypeID = sl.socialLoginTypeID
        				WHERE slf.facebookUserID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.facebookUserID#"> 
        				AND vs.socialTypeName = <cfqueryparam cfsqltype="cf_sql_varchar" value="facebook">
        	</cfquery>

        	<cfscript>
        		if( result.query.recordCount ) {
        			auth = application.accountObj.createAuthTokenForSocialLogin( userID = result.query.userid );

        			result['userid'] = auth.userID;
        			result['auth_token'] = auth.auth_token;
        			result['session_expiry'] = auth.session_Expiry;
        		} 
        	</cfscript>

         	<cfcatch>

         		<cfset result.message = errorMessage(message ='socialfacebook_get_found_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1008, extra = "method: /socialFacebook/GET", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

        	</cfcatch>

       </cftry>

        <cfset result['status'] = true />
        <cfset result['message'] = application.messages['socialfacebook_get_found_success']>
	  	<cfset logAction( actionID = 1007, extra = "method: /socialFacebook/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>