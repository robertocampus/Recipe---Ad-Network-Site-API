	<cfcomponent extends="taffyAPI.base" output="true">

	<!--- :: METHOD: insertPreferences :: --->
	<cffunction name="insertPreferences" access="public" hint="Insert Preferences" returntype="struct" output="false">
		<cfargument name="userID"	type="string" 	required="yes"  hint="User ID">
		<cfargument name="CGI" 		type="struct"   required="no"   default="#StructNew()#"	hint="CGI VARS structure">	
		
		<!--- :: init result structure --->	
		<cfset var result 		= StructNew()>
		<cfset var local  		= StructNew()>
		<cfset result.status  	= false>

		<!--- <cftry> --->

			<!--- // reset all preferences to 0 --->
			<cfquery datasource="#variables.datasource#" name="local.query">
		        INSERT INTO preferences ( preferenceTypeID, preferenceValue, userID )
				SELECT  preferenceTypeID, preferenceTypeDefault, <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				FROM val_preferencetype
			</cfquery>	
	  	
			<cfset result.status = true>
		
			<!--- // 224, 'Preferences: Inserted', 'User preferences inserted successfully.', 1 --->
		    <cfset local.logAction = logAction( actionID = 224, userID = 1, extra = "", cgi = arguments.cgi )>	
			
	<!--- 	<cfcatch>
			<!--- // 225, 'Error : Prefereces: Insert Error', 'Error encountered while inserting user preferences.', 1 --->
			<cfset local.logAction = logAction( actionID = 225, userID = 1, errorCatch = variables.cfcatch, cgi = arguments.cgi )>	
			</cfcatch> 
		</cftry> --->

		<cfreturn result />
	</cffunction>	

	<!--- :: METHOD: insertUserMeta :: --->
	<cffunction name="insertUserMeta" access="public" hint="Insert User Meta Records" returntype="struct" output="true">
		<cfargument name="userID"	type="string" required="yes" hint="User ID">

 		<!--- :: init result structure --->	
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />
		<cfset result.status  	= false />

		<!--- <cftry> --->
		    
			<cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
	 		
			<cfquery datasource="#variables.dataSource#" name="check">
				SELECT *
				FROM users
				WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
			</cfquery>	

			<cfquery datasource="#variables.dataSource#" name="insert_">	
				INSERT INTO users_meta ( userID, meta_key, meta_value )
					VALUES
						(
							<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="about_me">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#check.userAbout#">
						),
						(
							<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="last_activity">,
							<cfqueryparam cfsqltype="cf_sql_varchar" value="#check.userDateLastLogin#">
						)	
			</cfquery>
			
			<cfquery datasource="#variables.dataSource#" name="count">
				SELECT count(*) as total
				FROM favorites
				WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
			</cfquery>

			<cfquery datasource="#variables.dataSource#" name="insert_">	
				INSERT INTO users_meta ( userID, meta_key, meta_value )
				VALUES
					(
					<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="user_total_favorites">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#count.total#">
					)
			</cfquery>

			<cfquery datasource="#variables.dataSource#" name="count">
				SELECT count(*) as total
				FROM friends
				WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
	            AND friendStatusID = 2
			</cfquery>

			<cfquery datasource="#variables.dataSource#" name="insert_">	
				INSERT INTO users_meta ( userID, meta_key, meta_value )
				VALUES
					(
					<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="user_total_friends">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#count.total#">
					)
			</cfquery>

			<cfquery datasource="#variables.dataSource#" name="count">
				SELECT count(*) as total
				FROM blogs b
				INNER JOIN userblogs ub ON ub.blogID = b.blogID
				WHERE ub.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				AND b.statusID IN ( 3,5 )
			</cfquery>

			<cfquery datasource="#variables.dataSource#" name="insert_">	
				INSERT INTO users_meta ( userID, meta_key, meta_value )
				VALUES
					(
					<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="user_total_blogs">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#count.total#">
					)
			</cfquery>
			
			<cfquery datasource="#variables.dataSource#" name="count">
				SELECT count(*) as total
				FROM comments
				WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				AND commentStatusID = 2
			</cfquery>
					
			<cfquery datasource="#variables.dataSource#" name="insert_">	
				INSERT INTO users_meta ( userID, meta_key, meta_value )
				VALUES
					(
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="user_total_comments">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="#count.total#">
					),
					(
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="favorite_food">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="">
					),
					(
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="favorite_music">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="">
					),
					(
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="user_total_groups">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="0">
					),
					(
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="user_total_activity">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="0">
					),
					(
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="user_total_posts">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="0">
					),
					(
						<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="user_total_followers">,
						<cfqueryparam cfsqltype="cf_sql_varchar" value="0">
					)
			</cfquery>

		
            <cfset result.status = true />
		
			<!--- <cfcatch>
			<!--- // 615, 'Error: Update User', 'Error encountered while updating user details.', 1 --->
			<cfset local.logAction = logAction( actionID = 615, userID = 1, extra = "userID: #arguments.userID#", errorCatch = variables.cfcatch, cgi = arguments.cgi )>	
			</cfcatch> 
 		</cftry> --->
       
		<cfreturn result />
	</cffunction>

	<!--- :: METHOD: insertReferrer :: --->
	<cffunction name="insertReferrer" access="public" hint="Insert Referrer Record" returntype="struct" output="true">
		<cfargument name="referrerID"		type="string" 	required="yes" hint="User ID of referrer (ReferrerID)">
		<cfargument name="userID"	  		type="string" 	required="yes" hint="User ID of account created">
		<cfargument name="user"				type="struct" 	required="no"  default="#StructNew()#" hint="User Structure">
		<cfargument name="CGI" 				type="struct"  	required="no"  default="#StructNew()#" hint="CGI VARS structure">
		
		<!--- :: init result structure --->	
		<cfset var result		= StructNew() />
		<cfset var local		= StructNew() />
		<cfset result.status	= false />

		<!--- <cftry> --->
		
		<cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
		
		<cfquery datasource="#variables.dataSource#" name="local.query">
		INSERT INTO referrals 
					( 
						referrerID,
						userID,
						date_referred,
						isApproved,
						isActive
					)
		VALUES   (
					 <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.referrerID#">, 
					 <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">, 
					 '#local.timeStamp#',
					 0,
					 1
				)
		</cfquery>		
		
		<cfquery datasource="#variables.dataSource#" name="local.getLast"> 
			SELECT LAST_INSERT_ID() AS ID
		</cfquery>

		<!--- // 1540, 'Referrer: Inserted', 'Referrer record inserted.', 1 --->
		<cfset local.logAction = logAction( actionID = 1540, user = arguments.user, extra = "ReferrerID: #arguments.referrerID#; UserID: #arguments.userID#", cgi = arguments.cgi )>	
		 							
		<cfset result.thumbnailID = local.getLast.ID />	
		
		<cfset result.status = true />
			
			<!---
			<cfcatch> 
			
			<!--- // 1542, 'Referrer: Insert Error', 'Error while inserting Referrer record.', 1 --->
			<cfset local.logAction = application.dataObj.logAction( actionID = 1542, user = arguments.user, extra = "", errorCatch = variables.cfcatch, cgi = arguments.cgi )>	
				
		</cfcatch> 
		</cftry>--->
	   
		<cfreturn result />
	</cffunction>

	<cffunction name="socialFBUserIsExist" access="public" returntype="query" output="true" hint="The user is already exist or not login via Social Login.">
		<cfargument name="facebookUserID" type="numeric" required="true">

		<cfset local.query = "" />

		<cfquery datasource="#variables.datasource#" name="local.query">
            SELECT * FROM social_login_facebook 
                WHERE facebookUserID = <cfqueryparam value="#arguments.facebookUserID#" cfsqltype="cf_sql_varchar">
        </cfquery>

        <cfreturn local.query />
	</cffunction>

	<cffunction name="socialTwitterUserIsExist" access="public" returntype="query" output="true" hint="The user is already exist or not login via Social Login.">
		<cfargument name="twitterUserID" type="numeric" required="true">

		<cfset local.query = "" />

		<cfquery datasource="#variables.datasource#" name="local.query">
            SELECT * FROM social_login_twitter
                WHERE twitterUserID = <cfqueryparam value="#arguments.twitterUserID#" cfsqltype="cf_sql_varchar">
        </cfquery>

        <cfreturn local.query />
	</cffunction>

	<cffunction name="socialUserInstagramExist" access="public" returntype="query" output="true" hint="The user is alreay exist or not login via Social login.">
		<cfargument name="instagramUserID" type="numeric" required="true">
		
		<cfset local.query = "" />

		<cfquery datasource="#variables.datasource#" name="local.query">
			SELECT * FROM social_login_instagram
				WHERE instagramUserID = <cfqueryparam value="#arguments.instagramUserID#" cfsqltype="cf_sql_varchar">
		</cfquery>

		<cfreturn local.query />
	</cffunction>

	<cffunction name="insertSocialUserLogin" access="public" returntype="void" >
		<cfargument name="userID" type="numeric" required="true">
		<cfargument name="socialLoginTypeID" type="numeric" required="true">
		<cfargument name="socialLoginUserID" type="numeric" required="true">
		<cfargument name="isMainAccount" 	 type="numeric" required="true">

		<cfquery datasource="#variables.datasource#" name="result.query">
	        INSERT INTO social_login ( 
	                                    userID,
	                                    socialLoginTypeID,
	                                    socialLoginUserID,
	                                    isMainAccount
	                                    )
	        VALUES(
	                <cfqueryparam value="#arguments.userID#" 			cfsqltype="cf_sql_integer">,
	                <cfqueryparam value="#arguments.socialLoginTypeID#" cfsqltype="cf_sql_integer">,
	                <cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">,
	                <cfqueryparam value="#arguments.isMainAccount#" 	cfsqltype="cf_sql_bit">
	                )
	    </cfquery>

	</cffunction>


	<cffunction name="getSocialLoginUserDetails" access="public" returntype="query" output="true">
		<cfargument name="userID" type="numeric" required="true">
		<cfargument name="socialLoginTypeID" type="numeric" required="true">
		<cfargument name="socialLoginUserID" type="numeric" required="true">

		<cfset local.query = "" />

		<cfquery datasource="#variables.datasource#" name="local.query">
            SELECT * FROM social_login
                WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_numeric">
	                AND socialLoginTypeID = <cfqueryparam value="#arguments.socialLoginTypeID#" cfsqltype="cf_sql_integer">
	                AND socialLoginUserID = <cfqueryparam value="#arguments.socialLoginUserID#" cfsqltype="cf_sql_varchar">
        </cfquery>

        <cfreturn local.query />

	</cffunction>


	<cffunction name="insertUser" access="public" output="false" returntype="query" hint="Return users created DATA details by <code> POST </code> method">		
		<cfargument name="userName" 		required="false"	type="string"					hint="Username (string)" />
		<cfargument name="userEmail" 		required="true"		type="string"					hint="User's Email (string)" />
		<cfargument name="userFirstName" 	required="false"	type="string"	default=""  	hint="User's First name (string)" />
		<cfargument name="userLastName" 	required="false"	type="string"	default=""  	hint="User's Last name (string)" />
		<cfargument name="userAvatarURL" 	required="false"	type="string"	default=""  	hint="file path of User's profile_picture (string)" />
		<cfargument name="isConfirmed" 		required="false"	type="numeric"	default="1"		hint="User's account confirmation" />
		<cfargument name="active" 			required="false"	type="numeric"	default="1" 	hint="User's status" />
		<cfargument name="roleID"			required="true"		type="numeric"					hint="user's RoleID" />
			<cfset local.query = "" />

			<cfquery datasource="#variables.datasource#" name="local.qry" result="qry">
				INSERT INTO users (
									userName
									,userEmail
									,userFirstName
									,userLastName
									,userDateRegistered
									,userDateLastLogin
									,userAvatarURL
									,isConfirmed
									,active
									,roleID
								) 
				VALUES (
						<cfqueryparam value="#arguments.userName#"				cfsqltype="cf_sql_varchar"	/>
						,<cfqueryparam value="#arguments.userEmail#"			cfsqltype="cf_sql_varchar"	/>
						,<cfqueryparam value="#arguments.userFirstName#"		cfsqltype="cf_sql_varchar"	/>
						,<cfqueryparam value="#arguments.userLastName#"			cfsqltype="cf_sql_varchar"	/>
						,<cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#"  cfsqltype="cf_sql_timestamp" >
						,<cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#"  cfsqltype="cf_sql_timestamp" >
						,<cfqueryparam value="#arguments.userAvatarURL#"		cfsqltype="cf_sql_varchar"	/>
						,<cfqueryparam value="#arguments.isConfirmed#"			cfsqltype="cf_sql_integer"	/>
						,<cfqueryparam value="#arguments.active#"				cfsqltype="cf_sql_integer"	/>
						,<cfqueryparam value="#arguments.roleID#"				cfsqltype="cf_sql_integer"  />
						)
			</cfquery>

			<cfquery name="local.query" datasource="#variables.datasource#">
				SELECT * FROM users
				WHERE userID = <cfqueryparam value="#qry.GENERATED_KEY#" cfsqltype="cf_sql_integer">
			</cfquery>
			
		<cfreturn local.query />

	</cffunction>


	<!--- get the authentication details of user --->
	<cffunction name="readAuthentication" returntype="Query" output="true" access="private">
		<cfargument name="userID" required="yes" type="string" hint="User Name of existing confirmation user.">

		<cfquery datasource="#variables.datasource#" name="local.checkUser" >
			SELECT * FROM users_authentication
				WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
		</cfquery>

		<cfreturn local.checkUser />
	</cffunction>
	
	<!--- check password --->
	<cffunction name="checkPassword" returntype="Query" output="true" access="public">
		<cfargument name="userID" 		 required="yes" type="string" hint="User ID">
		<cfargument name="userPassword"  required="yes" type="string" hint="User Password">

		<cfquery datasource="#variables.datasource#" name="local.checkPassword" >
			SELECT userID 
			FROM users
			WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
			AND userPassword = <cfqueryparam value="#arguments.userPassword#" cfsqltype="cf_sql_varchar">
		</cfquery>

		<cfreturn local.checkPassword />
	</cffunction>	

	<cffunction name="createAuthTokenForSocialLogin" access="public" returntype="struct" output="true" hint="Log on User. If user log on Successfully, u can receive auth_token." >
		<cfargument name="userID" required="yes" type="string" hint="User Name of existing confirmation user.">

		<cfset result = structNew() />
		<cfset local.query = "" />
		
		<!--- check auth_token is already available or not for that userID --->
		<cfscript>
			local.checkUser = readAuthentication( userID = arguments.userID );

			if( local.checkUser.recordCount EQ 1 AND dateCompare(now(), local.checkUser.sessionExpiry) NEQ -1 ) {
				local.attributes = {};
				local.attributes.auth_token = local.checkUser.auth_token;

				// delete expiry auth_token
				httpRequest( methodName = 'DELETE', endPointOfURL = '/authorize', timeout = 3000, parameters = local.attributes );

				local.checkUser = readAuthentication( userID = arguments.userID );

			} else {

				result.userID = local.checkUser.userID;
				result.auth_token = local.checkUser.auth_token;
				result.session_Expiry = local.checkUser.sessionExpiry;
			}

		</cfscript>

		<!--- if auth_token not exist, allow to insert --->
		<cfif local.checkUser.recordCount NEQ 1 >	

			<cfset result.userID = arguments.userID >
			<cfset result.auth_token = createUUID() />
			<cfset result.session_Expiry = dateTimeFormat(dateAdd("n", 30, now()), 'yyyy-mm-dd HH:nn:ss') />

			<!--- // insert auth_token for authenticated user --->
			<cfquery datasource="#variables.dataSource#" name="local.query">
				INSERT INTO users_authentication ( 
													userID,
													auth_token,
													IP,
													sessionExpiry
												)
				VALUES (
						<cfqueryparam value="#result.userID#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#result.auth_token#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#CGI.REMOTE_ADDR#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#result.session_Expiry#" cfsqltype="cf_sql_timestamp">
						)
			</cfquery>

		</cfif>

		<cfreturn result />

	</cffunction>

	<cffunction name="sendEmailToAny" access="public" hint="Send Email" returntype="struct" output="true">
		<cfargument name="emailBody" 	type="string"  required="yes" hint="Email Body">
		<cfargument name="emailSubject" type="string"  required="no" default="#variables.title# : Contact Form Received" hint="Email Body">
		<cfargument name="emailFrom" 	type="string"  required="no" default="#variables.supportEmail#" hint="Email From Address">
		<cfargument name="senderName" 	type="string"  required="no" default="Support" hint="Used in subject">
		<cfargument name="TO"	 	    type="string"   required="no" default="#variables.adminEmail#" hint="Email addresses TO recipient(s) - defaults to admin email">
		<cfargument name="CC"	 	    type="string"   required="no" default="" hint="Email addresses of CC recipient(s)">
 		  
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset var local  = StructNew() />
		<cfset result.status  	= false />

		 <!--- <cftry>  ---> 
 
  		   
		    <cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
  				
				<cfmail
					      to = "#arguments.to#"
					      cc = "#arguments.cc#" 
					    from = "#variables.title# #arguments.senderName# <#arguments.emailFrom#>"
					 replyto = "#variables.title# #arguments.senderName# <#arguments.emailFrom#>"
					 subject = "#arguments.emailSubject#"
					    type = "html"
					username = "#variables.emailUsername#"
					server   = "#variables.emailServer#"
					port     = "#variables.emailServerPortSMTP#"
					usessl   = "#variables.emailServerSSL#"
					password = "#variables.emailPassword#">
					#arguments.emailBody#
				 </cfmail>
  
				 
<!--- 				 <cfoutput>userEmail: #userEmail#
				 local.CC: #local.CC#
				 local.getEmail.emailFrom: #local.getEmail.emailFrom#
				 local.getEmail.emailSubject: #local.getEmail.emailSubject#
				 local.getEmail.emailBody: #local.getEmail.emailBody#</cfoutput>	 --->
				 
				<!--- // 400, 'Email : Sent ', 'System sent user email', 1 --->
				<cfset logAction( actionID = 400, extra = "to = #arguments.to#" )>			 
 										
		    <cfset result.status = true />
   		
<!---  		<cfcatch>
			
			<!--- // 405, 'Email : Error', 'Error encountered while sending email', 1 --->
			<cfset logAction( actionID = 105, extra = "userEmail: #arguments.userEmail# - userFirstName: #arguments.userFirstName# - userLastName: #arguments.userLastName# - userPassword = #arguments.userPassword# - userPasswordReminder: #arguments.userPasswordReminder#", errorCatch = variables.cfcatch, cgi = arguments.cgi )>	
				
		</cfcatch> 
		
	  </cftry>   ---> 
 		 												
    
		<cfreturn result />


		
	</cffunction>


  <!--- //Method: insertResetPassword --->
	<cffunction name="insertResetPassword" access="public" hint="Insert Reset Password Record" returntype="struct" output="true">
		<cfargument name="email"	type="string" required="yes" hint="Email of user requesting password reset">
		<cfargument name="uuid"		type="string" required="yes" hint="Unique UUID for password reset request">
		<cfargument name="userID"	type="string" required="yes" hint="Unique USER ID for reset request">
		    
		<!--- <cfargument name="user"		type="struct" required="no"  default="#StructNew()#" hint="User Structure"> --->
		<!--- <cfargument name="CGI" 		type="struct" required="no"  default="#StructNew()#" hint="CGI VARS structure"> --->
  	
		<!--- :: init result structure --->	
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />
		<cfset result.status  	= false />

		<cftry>
		
			<cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
	 	
	 		<!--- // deactivate prior requests --->
			<cfquery datasource="#variables.datasource#" name="local.verify"> 
				UPDATE resetpassword
				  SET active = 0
				WHERE resetPasswordEmail = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.email#" maxlength="100">	
			</cfquery>
			
			<!--- // adds new password reset request --->
 			<cfquery datasource="#variables.datasource#" name="local.query">
				INSERT INTO resetpassword 
							( 
								resetPasswordUUID, 
								resetPasswordEmail, 
								resetPasswordUserID,
								resetPasswordCreateDate, 
								active
							)
				VALUES   (
							 <cfqueryparam cfsqltype="cf_sql_varchar"   value="#arguments.uuid#">, 
							 <cfqueryparam cfsqltype="cf_sql_varchar"   value="#arguments.email#">, 
							 <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.userID#">,
							 '#local.timeStamp#',
							 1
						)
			</cfquery>		
			
			<cfquery datasource="#variables.datasource#" name="local.getLast"> 
				SELECT LAST_INSERT_ID() AS ID
			</cfquery>
		
			<!--- // 322, 'Resest Password: Inserted', 'Reset password request inserted', 1 --->
			<cfset local.logAction = application.dataObj.logAction( actionID = 322,  extra = "resetPasswordID = #local.getLast.ID#" )>	
			 							
			<cfset result.status = true />

   		
	  		<cfcatch> 
				
				<!--- // 323, 'Reset Password: Error', 'Error encountered while inserting reset password request.', 1 --->
				<cfset local.logAction = application.dataObj.logAction( actionID = 323,  extra = "", errorCatch = variables.cfcatch )>	
					
			</cfcatch> 
		</cftry>
  	 			
		<cfreturn result />

	</cffunction>




	<!--- :: METHOD: insertContestParticipantActivity :: --->
	<cffunction name="insertContestParticipantActivity" access="public" hint="Insert contest winner record" returntype="struct" output="true">
		<cfargument name="contestWinnerID" 		 type="string" 	required="yes" hint="Contest Winner ID">
		<cfargument name="contestActivityTypeID" type="string" 	required="yes" hint="">
		<cfargument name="contestActivityURL"	 type="string" 	required="yes" hint="Contest Activity URL">
		<cfargument name="contestActivityText"	 type="string" 	required="no" default="" hint="Contest Notes (text)">
		
		<cfargument name="contestID"			 type="string" 	required="no" hint="Contest ID">
		<cfargument name="contestRunID"			 type="string" 	required="no" hint="Contest Run ID">
		<cfargument name="blogID"				 type="string" 	required="no" hint="Blog ID">	
		<cfargument name="userID"				 type="string" 	required="no"  default="0" hint="User ID">
		
		<cfargument name="CGI" type="struct"   required="no"  default="#StructNew()#" 	hint="CGI VARS structure">
 	
 		<!--- :: init result structure --->	
		<cfset var result 	 = StructNew() />
		<cfset var local  	 = StructNew() />
		<cfset result.status = false />
		
		<!---<cfdump var="#arguments#">--->
		<cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
  			
		<!--- <cftry>  --->
		
		    <cfquery datasource="#variables.datasource#" name="local.insertcontestrun">
                INSERT INTO contest_activity
                	   (
						contestWinnerID,		
						contestActivityTypeID,
						contestActivityURL,
						contestActivityText,
						<cfif isDefined("arguments.contestID")>contestID,</cfif>
						<cfif isDefined("arguments.contestRunID")>contestRunID,</cfif>
						<cfif isDefined("arguments.blogID")>blogID,</cfif>
						<cfif isDefined("arguments.userID")>userID,</cfif>
						contestActivityDate
						)
				VALUES (  
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestWinnerID#">, 
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestActivityTypeID#">, 
						<cfqueryparam cfsqltype="cf_sql_string"    value="#left(arguments.contestActivityURL,255)#">, 
						<cfqueryparam cfsqltype="cf_sql_varchar"      value="#arguments.contestActivityText#">, 
						<cfif isDefined("arguments.contestID")><cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestID#">,</cfif>
						<cfif isDefined("arguments.contestRunID")><cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestRunID#">,</cfif>
						<cfif isDefined("arguments.blogID")><cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.blogID#">,</cfif>
						<cfif isDefined("arguments.userID")><cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.userID#">,</cfif>
						<cfqueryparam cfsqltype="cf_sql_date"   value="#local.timeStamp#">
						)
             </cfquery>		
			
            <cfquery datasource="#variables.datasource#" name="local.getLast"> 
            	SELECT LAST_INSERT_ID() AS ID
            </cfquery>

            <cfset result.contestActivityID = local.getLast.ID />			
				
			<!--- // 1126, Contest: Insert Activity, Contest winner activity inserted successfully., 1 --->
            <cfset local.logAction = application.dataObj.logAction( actionID = 1126, userID = 1, blogID = arguments.blogID, extra = "contestActivityID : #local.getLast.ID#", cgi = arguments.cgi )>	
        
            <cfset result.status = true />

<!--- 		
			<cfcatch>
			<!--- // 1127, Contest:Error on Insert Activity, Error encountered while inserting contest activity., 1 --->
			<cfset local.logAction = application.dataObj.logAction( actionID = 1127, userID = 1, errorCatch = variables.cfcatch, cgi = arguments.cgi )>	
			</cfcatch> 
 		</cftry>
--->       
		<cfreturn result />
	</cffunction>


	<cffunction name="getAvailableContests" access="public" hint="Return Current Avaialble Contests Listing DATA" returntype="struct" output="false">
		<cfargument name="sponsorID" 			type="string" default="" required="no" hint="Sponsor ID">
		<cfargument name="contestID" 			type="string" default="" required="no" hint="Contest ID">
		<cfargument name="contestIsAvailable" 	type="string" required="no" hint="Contest Is Available (1 = list only promotions that should appear in the user promotions tab)">
		<cfargument name="userID" 				type="string" required="no" hint="User ID - to check if already submitted or participated">
		
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result.status  	= false />
		<cfset result.message 	= "" />

		<!---<cftry>---> 

		    <cfquery datasource="#variables.datasource#" name="result.query" cachedwithin="#CreateTimeSpan(0,0,0,0)#">
				SELECT
					C.*,	
					P.prizeName,
					VR.contestRegionName,
					VC.contestTypeName,
					
					S.sponsorName,
					S.sponsorURL,
					
					CI.imageFileName,
					CI.imageFileNameHalf,
					CI.imageThumbFileName,
					CI.imageAlt,
					
					lcase(VC.contestTypeName) AS contestTypeName,
					
					( SELECT count(*) FROM contestwinners CW WHERE CW.contestID = C.contestID AND CW.contestWinnerStatusID IN ( 9,10 ) ) as contestParticipantsCount,
					
					( SELECT CR.contestRunID FROM contestrun CR where CR.contestID = C.contestID ORDER BY CR.contestRunID DESC LIMIT 0,1 ) as contestRunID,
					
					( SELECT CWW.contestWinnerID FROM contestwinners CWW where CWW.contestID = C.contestID AND CWW.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#"> LIMIT 0,1 ) as contestWinnerID
					 
		
			FROM contests C
			LEFT JOIN val_contesttype   VC  ON VC.contestTypeID = C.contestTypeID
			LEFT JOIN val_contestregion VR  ON VR.contestRegionID = C.contestRegionID
			 LEFT JOIN sponsors 	    S	ON S.sponsorID = C.sponsorID
			 LEFT JOIN prizes 			P	ON P.prizeID = C.prizeID 
			 LEFT JOIN images 			CI	ON CI.imageID = C.imageID
	 
			
			WHERE C.active = 1
			 
			 	<cfif isDefined("arguments.checkDate")>
					AND (  C.contestExpireDate >= DATE(NOW())  OR C.contestExpireDate IS null  )
					AND (  C.contestPublishDate <= DATE(NOW()) OR C.contestPublishDate IS null ) 
				</cfif>
				
				<cfif isDefined("arguments.contestIsAvailable")>
					AND C.contestIsAvailable = 1
				</cfif>

				<cfif isDefined("arguments.contestID")>
					<cfif isNumeric(arguments.contestID)>
					AND C.contestID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.contestID#">
					</cfif>
				</cfif>

			ORDER BY C.contestName ASC
		</cfquery>
		
		<cfif result.query.recordCount GT 0>
			<cfset result.status = true />
		</cfif>
		   
		    <!---<cfcatch>
			
			<!--- :: degrade gracefully :: --->
			<cfset result.query.recordCount = 0>
			<cfset result.message = 999>

			<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
			<cfset local.logAction = logAction( actionID = 661, extra = "method: getContests", errorCatch = variables.cfcatch  )>	
		  
		</cfcatch>
		
	  </cftry> --->

		<cfreturn result />
		
	</cffunction>


	<!--- :: METHOD: insertLead :: --->
	<cffunction name="insertLead" access="public" hint="Insert Lead Record" returntype="struct" output="true">
		<cfargument name="leadQuestion"			type="string" 	required="yes" hint="Text of lead comments/question">
		<cfargument name="leadCompanyName"		type="string" 	required="yes" hint="Company Name">
		<cfargument name="leadFirstName"		type="string" 	required="yes" hint="First Name provided in lead form">
		<cfargument name="leadEmail"			type="string" 	required="yes" hint="Email address provided in lead form">
		<cfargument name="leadURL"				type="string" 	required="no" default=""  hint="URL provided in lead form">
		<cfargument name="leadPhoneWork"		type="string" 	required="no" default=""  hint="Phone number provided in lead form">

		<!--- :: init result structure --->	
		<cfset var result		= StructNew() />
		<cfset var local		= StructNew() />
		<cfset result.status	= false />

		<!---<cftry>--->
		
			<cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
	  	    
			<cfquery datasource="#variables.datasource#" name="local.query">
			INSERT INTO leads 
						( 
							leadCompanyName,
							leadFirstName, 
							leadEmail,
							leadPhoneWork,
							leadQuestion,
							leadDateCreated,
							active
						)
			VALUES   (
						 
						 <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#left(arguments.leadCompanyName, 255)#" maxlength="255">,
						 <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#left(arguments.leadFirstName, 255)#" maxlength="255">,
						 <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#left(arguments.leadEmail, 100)#" maxlength="100">,
						 <cfqueryparam cfsqltype="cf_sql_varchar" 	value="#left(arguments.leadPhoneWork, 45)#" maxlength="45">,
						 <cfqueryparam cfsqltype="cf_sql_varchar"	value="#arguments.leadQuestion#"			maxlength="65535">,
						  '#local.timeStamp#',
						 1
					)
			</cfquery>		
			
			<cfquery datasource="#variables.datasource#" name="local.getLast"> 
				SELECT LAST_INSERT_ID() AS ID
			</cfquery>
		
			<!--- // 252, 'Leads: Inserted', 'Lead inserted successfully.', 1 --->
			<cfset local.logAction =logAction( actionID = 252,  extra = "leadID = #local.getLast.ID#")>	
			 							
			<cfset result.ticketID = local.getLast.ID />	
			 	
			<cfset result.status = true />
   		
<!---		<cfcatch> 
			
			<!--- // 251, 'Support: Error on Insert Lead', 'Error encountered while inserting lead record.', 1 --->
			<cfset local.logAction = application.dataObj.logAction( actionID = 251, user = arguments.user, extra = "", errorCatch = variables.cfcatch, cgi = arguments.cgi )>	
				
		</cfcatch> 
		</cftry>--->
  
      
		<cfreturn result />
	</cffunction>




	<cffunction name="getUserSocialDetails" access="public" hint="Return User Social DATA" output="false">
		<cfargument name="UserID" 		type="numeric" 	required="yes" hint="User ID">

 		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message']	= ''>
		<cfset local.resultFacebook   = {} >
		<cfset local.resultTwitter    = {} >
		<cfset local.resultGooglePlus = {} >
		<cfset local.resultInstagram  = {} >
 
		<cftry>

	  		<cfquery datasource="#variables.datasource#" name="local.socialTypes">

				SELECT 
					* 
					FROM social_login sl
					LEFT JOIN val_socialtype vs ON sl.socialLoginTypeID = vs.socialTypeID
	 				WHERE 	sl.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.UserID#">
	 					AND vs.active = 1				
	 			
			</cfquery>			

			<cfloop query="local.socialTypes">

				<cfif socialLoginTypeID EQ 4 >
					
					<cfquery datasource="#variables.datasource#" name="local.socialFacebook">
						
						SELECT 
							slf.*
							FROM social_login_facebook slf
								INNER JOIN social_login sl ON sl.socialLoginUserID = slf.facebookUserID
								WHERE facebookUserID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#socialLoginUserID#">

					</cfquery>
					<cfset structInsert( local.resultFacebook, "socialtypename", "facebook" )>
					<cfset structInsert( local.resultFacebook, "link", local.socialFacebook.link )>

				</cfif>

				<cfif local.socialTypes.socialLoginTypeID EQ 13 >
					
					<cfquery datasource="#variables.datasource#" name="local.socialTwitter">
						
						SELECT 	slt.* 
							FROM 
								social_login_twitter slt 
								INNER JOIN social_login sl ON sl.socialLoginUserID = slt.twitterUserID
							WHERE twitterUserID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#socialLoginUserID#">

					</cfquery>					
					<cfset structInsert( local.resultTwitter, "socialtypename", "twitter" )>
					<cfset structInsert( local.resultTwitter, "link", local.socialTwitter.profile_location )>
				</cfif>

				<cfif local.socialTypes.socialLoginTypeID EQ 16 >
					
					<cfquery datasource="#variables.datasource#" name="local.socialInstagram">
						
						SELECT 
							sli.*
								FROM social_login_instagram sli
								INNER JOIN social_login sl ON sl.socialLoginUserID = sli.instagramUserID
								WHERE instagramUserID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#socialLoginUserID#">

					</cfquery>

					<cfset structInsert( local.resultGooglePlus, "socialtypename", "instagram" )>
					<cfset structInsert( local.resultGooglePlus, "link", local.socialInstagram.website )>

				</cfif>


				<cfif local.socialTypes.socialLoginTypeID EQ 17 >
					
					<cfquery datasource="#variables.datasource#" name="local.socialgoogle">
						
						SELECT 
							slg.*
							
							FROM social_login_google slg
								INNER JOIN social_login sl ON sl.socialLoginUserID = slg.id
								WHERE id = <cfqueryparam cfsqltype="cf_sql_varchar" value="#socialLoginUserID#">

					</cfquery>

					<cfset structInsert( local.resultInstagram, "socialtypename", "google" )>
					<cfset structInsert( local.resultInstagram, "link", local.socialgoogle.url )>

				</cfif>

			</cfloop>

			<cfset result.dataset = [] >			
			
			<cfif NOT structIsEmpty(local.resultFacebook) >
				<cfset arrayAppend(result.dataset, local.resultFacebook)>				
			</cfif>
			<cfif NOT structIsEmpty(local.resultTwitter)>
				<cfset arrayAppend(result.dataset, local.resultTwitter)>				
			</cfif>
			<cfif NOT structIsEmpty(local.resultGooglePlus)>
				<cfset arrayAppend(result.dataset, local.resultGooglePlus)>				
			</cfif>
			<cfif NOT structIsEmpty(local.resultInstagram)>
				<cfset arrayAppend(result.dataset, local.resultInstagram)>				
			</cfif>

			<cfcatch>
		      	<!--- :: degrade gracefully :: --->
		     	<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
		       
		     	<!--- // 666, 'Database Error', 1 --->
				<cfset logAction( actionID = 666, extra = "method: /mySocialNetwork/{userID}/GET", errorCatch = variables.cfcatch  )>	
				<cfreturn representationOf(result.message).withStatus(500)>
			  
	        </cfcatch>
			
	    </cftry>

	    <!--- // Found? --->		
		<cfif NOT arrayIsEmpty(result.dataset)>
			<cfset result.status = true />
		</cfif>

	   <cfreturn result>

	</cffunction>

</cfcomponent>