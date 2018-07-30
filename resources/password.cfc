<cfcomponent extends="taffyAPI.base" taffy:uri="/password/" hint="used to insert or update the users  password.">

	<!--- :: METHOD: resetUserPassword :: --->
	<cffunction name="PUT" access="public" hint="Insert Reset Password Record" returntype="struct" output="true">
		<cfargument name="uuid"			type="string" required="yes" 	hint="Unique UUID for password reset request">
		<cfargument name="newpassword"	type="string" required="yes"   hint="newPassword">
	
		
		<!--- :: init result structure --->	
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />
		<cfset result['status'] = false />
		<cfset result['message']="">    

		<cftry>
	 	
	 		<!--- // check if there is a current record for reset password --->
			<cfquery datasource="#variables.datasource#" name="local.getUUID"> 

				SELECT resetPasswordID, resetPasswordEmail, resetPasswordUserID
				  FROM resetpassword
				 WHERE resetPasswordUUID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.uuid#" maxlength="35">	
				   AND active = <cfqueryparam value="1" cfsqltype="cf_sql_integer">

			</cfquery>
			
			<!--- // START: check if an active UUID is present --->
			<cfif local.getUUID.recordCount EQ 0>
				<!--- // 324, 'Resest Password: UUID not found', 'User submitted UUID is not found or not active', 1 --->
				<cfset logAction( actionID = 324, extra = "method: /password/PUT")>
				<cfreturn noData().withStatus(404)>	

			<cfelse>
			
				<!--- // update user password --->
	 			<cfquery datasource="#variables.datasource#" name="local.query">

					UPDATE users 
					   SET userPassword = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.newPassword#" maxlength="20">
					 WHERE userID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#local.getUUID.resetPasswordUserID#" maxlength="35">

				</cfquery>				
			
				<!--- // deactivate resest password request --->
	 			<cfquery datasource="#variables.datasource#" name="local.query">

					UPDATE resetpassword 
					   SET active = <cfqueryparam value="0" cfsqltype="cf_sql_integer">
					 WHERE resetPasswordUUID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.uuid#" maxlength="35">

				</cfquery>		
				
				<!--- // 325, 'Reset Password: Completed', 'Reset password process completed', 1 --->
				<cfset logAction( actionID = 325,  extra = "method: /password/PUT" )>	
				 				
				<cfset result.userID = local.getUUID.resetPasswordUserID />	 				
				<cfset result.message = application.messages['password_put_update_success']>					
				<cfset result.status = true />

			<!--- // END: check if an active UUID is present --->
			</cfif>   	

		
			<cfcatch> 
			
			<!--- // 323, 'Reset Password: Error', 'Error encountered while inserting reset password request.', 1 --->
				<cfset result.message = errorMessage(message = 'password_put_update_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 323, extra = "method: /password/PUT", errorCatch = variables.cfcatch )>	
				<cfreturn representationOf(result.message).withStatus(500)>

			</cfcatch> 

		</cftry>

		<cfset result.status  	= true />
		<cfset result.userID = local.getUUID.resetPasswordUserID>
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

	<!--- :: METHOD: insertResetPassword :: --->
	<cffunction name="POST" access="public" hint="Insert Reset Password Record" returntype="struct" output="true">
		<cfargument name="email"	type="string" required="yes" hint="Email of user requesting password reset">
		<cfargument name="userID"	type="string" required="yes" hint="Unique USER ID for reset request">
  		
		<!--- :: init result structure --->	
		<cfset var result 		= StructNew() />
		<cfset var local  		= StructNew() />

		<cfset local.uuid = createUUID()>
		<cfset result['status']  	= false />
		<cfset result['message']	= ''>

		<cftry>
	
	  		<cfquery name="local.getUser" datasource="#variables.datasource#">

	  			SELECT * FROM users
	  			WHERE userID = <cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_varchar">
	  			AND userEmail = <cfqueryparam value="#arguments.email#" cfsqltype="cf_sql_varchar">

	  		</cfquery>
			
			<cfif NOT local.getUser.recordCount >

				<cfset logAction( actionID = 324, extra = "method: /password/POST")>
				<cfreturn noData().withStatus(404)>	
				
			</cfif>
	 	
	 		<!--- // deactivate prior requests --->
			<cfquery datasource="#variables.datasource#" name="local.verify"> 

				UPDATE resetpassword
				  SET active = <cfqueryparam value="0" cfsqltype="cf_sql_integer">
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
								<cfqueryparam cfsqltype="cf_sql_varchar"   value="#local.uuid#">, 
								<cfqueryparam cfsqltype="cf_sql_varchar"   value="#arguments.email#">, 
								<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.userID#">,
								<cfqueryparam value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#"  cfsqltype="cf_sql_timestamp" >,
								<cfqueryparam value="1" cfsqltype="cf_sql_integer">
						)
			</cfquery>		
			
			<cfquery datasource="#variables.datasource#" name="local.getLast"> 
				SELECT LAST_INSERT_ID() AS ID
			</cfquery>
		
			<!--- // 322, 'Resest Password: Inserted', 'Reset password request inserted', 1 --->
			<cfset logAction( actionID = 322, extra = "resetPasswordID = #local.getLast.ID#" )>

			<cfquery name="result.query" datasource="#variables.datasource#">

				SELECT * FROM resetpassword
				WHERE resetPasswordID = <cfqueryparam value="#local.getLast.ID#" cfsqltype="cf_sql_integer">

			</cfquery>						

			<cfset result.status = true />
			<cfset result.message = application.messages['password_post_add_success']>
   		
	  		<cfcatch> 

				<cfset result.message = errorMessage( message = 'password_post_add_error', error = variables.cfcatch )>
				<!--- // 323, 'Reset Password: Error', 'Error encountered while inserting reset password request.', 1 --->
				<cfset logAction( actionID = 323, extra = "method: /password/POST", errorCatch = variables.cfcatch )>	
				<cfreturn representationOf(result.message).withStatus(500)>

			</cfcatch> 

		</cftry>
  	 			
<!--- 
	
DROP TABLE IF EXISTS `clubcomida_db`.`resetpassword`;
CREATE TABLE  `clubcomida_db`.`resetpassword` (
  `resetPasswordID` int(10) unsigned NOT NULL auto_increment,
  `resetPasswordUUID` varchar(35) default NULL,
  `resetPasswordEmail` varchar(100) default NULL,
  `resetPasswordCreateDate` datetime default NULL,
  `resetPasswordUpdateDate` datetime default NULL,
  `active` tinyint(1) unsigned NOT NULL default '1',
  PRIMARY KEY  (`resetPasswordID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;	

 	
--->
      
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>	