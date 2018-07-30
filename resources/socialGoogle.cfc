<cfcomponent extends="taffyAPI.base" taffy:uri="/googlePlus/" hint="Inserting social Login Details for FaceBook">

	<cffunction name="POST" access="public" output="true" returntype="Struct" hint="can create Social DATA using <code>POST</code>">
        <cfargument name="access_token" 		required="yes"  type="string"  	 />
		<cfargument name="id"           		required="yes"  type="string" 	/>
        <cfargument name="id_token"     		required="yes"   type="string"  	 />
        <cfargument name="emails"        		required="yes"  type="string"  	default="" />
        <cfargument name="session_state"       	required="no"   type="string"  	default="" />
        <cfargument name="displayName"   		required="no"   type="string"  	default="" />
        <cfargument name="gender"       		required="no"   type="string"  	default="" />
        <cfargument name="language"    			required="no"   type="string"  	default="" />
        <cfargument name="url"         			required="no"   type="string"  	default="" />
        <cfargument name="image_url" 			required="no"  	type="string" 	default="" />
        <cfargument name="followers_count"      required="no"   type="numeric"  default="0"/>
        <cfargument name="connectedStatus"      required="no"   type="numeric"  default="1"/>
        
        <cfset result = structNew() />
        <cfset result['status'] = false />
        <cfset result['message'] = ''>

        <cftry>

	        <cfquery name="local.query" datasource="#variables.datasource#" result="qry">
	            INSERT INTO social_login_google (
	                                                access_token,
	                                                id,
	                                                id_token,
	                                                emails,
	                                                session_state,
	                                                displayName,
	                                                gender,
	                                                language,
	                                                url,
	                                                image_url,
	                                                followers_count,
	                                                connectedStatus
	                                               )
	            VALUES (
	                        <cfqueryparam value="#arguments.access_token#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.id_token#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.emails#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.session_state#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.displayName#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.gender#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.language#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.url#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.image_url#" cfsqltype="cf_sql_varchar">,
	                        <cfqueryparam value="#arguments.followers_count#" cfsqltype="cf_sql_integer">,
	                        <cfqueryparam value="#arguments.connectedStatus#" 	cfsqltype="cf_sql_bit">
	                    )
	        </cfquery>

	        <cfquery name="result.query" datasource="#variables.datasource#">
				SELECT * FROM social_login_google
				WHERE socialLoginID = <cfqueryparam value="#qry.GENERATED_KEY#" cfsqltype="cf_sql_integer">
			</cfquery>

			<cfcatch>

				<cfset result.message = errorMessage( message = 'socialgoogleplus_post_add_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1006, extra = "method: /googlePlus/POST", errorCatch = variables.cfcatch )>
				
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
		</cftry>
			 
		<cfset result['status'] = true />
		<cfset result.message = application.messages['socialgoogleplus_post_add_success'] />

	  	<cfset logAction( actionID = 1005, extra = "method: /googlePlus/POST" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="GET" access="public" returntype="Struct" output="true" hint="to check the facebook user already registered or new one.">
		<cfargument name="id" required="true" type="numeric" hint="google ID">

		<cfset result = structNew() />
        <cfset result['status'] = false />
        <cfset result['message'] = ''>

        <cftry>
        	
        	<cfquery datasource="#variables.datasource#" name="result.query">
        		SELECT u.userID, u.userName, u.userEmail, slg.* FROM users AS u 
					INNER JOIN social_login AS sl ON u.userID = sl.userID
					INNER JOIN social_login_google AS slg ON sl.socialLoginUserID = slg.id
					INNER JOIN val_socialtype AS vs ON vs.socialTypeID = sl.socialLoginTypeID
        				WHERE slg.id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.id#"> 
        				AND vs.socialTypeName = <cfqueryparam cfsqltype="cf_sql_varchar" value="google">
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
         		<cfset result.message = errorMessage( message = 'socialgoogleplus_get_found_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 1008, extra = "method: /googlePlus/GET", errorCatch = variables.cfcatch )>
				
				<cfreturn noData().withStatus(500) />
        	</cfcatch>

       </cftry>

        <cfset result['status'] = true />
        <cfset result.message = errorMessage(message = 'socialgoogleplus_get_found_success')>
	  	<cfset logAction( actionID = 1007, extra = "method: /googlePlus/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>