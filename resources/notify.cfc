<cfcomponent extends="taffyAPI.base" taffy:uri = "/notify/" hint ="notity used to send an email to user">
	
	<cffunction name="post" access="public" returntype="Struct" hint="">
		<cfset result = structNew()>
		<cfset result['status'] = false>
		<cfset result['message'] = "">
		<cfset result['error'] = "">

		<cfargument name="notificationName" type="string" required="true" hint="">
		<cfargument name="attributes" type="string" required="false" hint="Form data that submitted from front-end">

		<cfset structAppend(arguments,deserializeJSON(arguments.attributes))>

		<cfswitch expression="#arguments.notificationName#">
			
			<cfcase value="sendEmailToUser">

			<!---emailID AND TO userID where required,
			 	<cfparam name = "emailID" 		   		 default = ""> 
				<cfparam name = "TOuserID" 				 default = "">  --->
				<cfparam name = "arguments.CCuserID" 			 default = ""> 
				<cfparam name = "arguments.blogID" 				 default = "0" type="numeric"> 
				<cfparam name = "arguments.insertUserFirstName"  default = "true"> 
				<cfparam name = "arguments.insertBlogID" 		 default = "true"> 
				<cfparam name = "arguments.insertBlogTitle"		 default = "true"> 
				<cfparam name = "arguments.insertBlogURL" 		 default = "true"> 
				<cfparam name = "arguments.insertUserPassword" 	 default = "true"> 
				<cfparam name = "arguments.insertUserEmail" 	 default = "true"> 
				<cfparam name = "arguments.insertConfirmationCode" default = "false"> 
				<cfparam name = "arguments.insertURL" 			 default = "true"> 
				<cfparam name = "arguments.insertTITLE" 		 default = "true"> 
								

				<!--- <cfset local.timestamp =  "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), "HH:MM:SS")#"> --->
				<cftry>
					
					<cfif arguments.blogID NEQ 0>
						<cfquery datasource="#variables.datasource#" name="local.getBlog">
						SELECT DISTINCT blogTitle, blogURL
						  FROM blogs
						 WHERE blogID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#">
		 	        	</cfquery>
					</cfif>

					<cfquery datasource="#variables.datasource#" name="local.getTOAddress">
						SELECT DISTINCT userEmail, userID, userFirstName, userPassword, userConfirmationCode
						FROM users
						WHERE userID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.TOuserID#" list="yes" separator=","> )
	 	       		</cfquery>
	 	       		
	 	       		<cfif local.getTOAddress.recordCount GT 0>
	 	       			<!--- start: need to get CC? --->
	 	       			<cfif arguments.CCuserID NEQ "">
	 	       				<cfquery datasource="#variables.datasource#" name="local.getCCAddress">
								SELECT DISTINCT userEmail, userID, userFirstName, userPassword
								FROM users
								WHERE userID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.CCuserID#" list="yes" separator=","> )
							</cfquery>
							<cfset local.CC = ValueList(local.getCCAddress.userEmail)>
						<cfelse>
							<cfset local.CC = "">	
	 	       			</cfif>

	 	       			<!--- end: need to get CC? --->
					
						<!--- get email text  --->
						<cfquery datasource="#variables.datasource#" name="local.getEmail">
							SELECT emailSubject, emailBody, emailFrom, emailRequireID
							  FROM emails
							 WHERE emailID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.emailID#">
						</cfquery>		
						
						<cfset local.thisEmailBody = local.getEmail.emailBody>	

						<cfif isDefined("arguments.replaceString")>
							<cfset local.thisEmailBody = Replace(local.thisEmailBody, "__replaceString__", arguments.replaceString, "ALL")>
						</cfif>
	 					<cfif arguments.insertBlogID>					
							<cfset local.thisEmailBody = Replace(local.thisEmailBody, "***", arguments.blogID, "ALL")>
							<cfset local.thisEmailBody = Replace(local.thisEmailBody, "__blogID__", arguments.blogID, "ALL")>
						</cfif>	
   						<!--- start: Any TO User ID email(s) found? --->

						<cfif arguments.blogID NEQ 0>
						
							<cfif arguments.insertBlogTitle>
								<cfset local.thisEmailBody = Replace(local.thisEmailBody, "__blogTitle__", local.getBlog.blogTitle, "ALL")>
							</cfif>

							<cfif arguments.insertBlogURL>
								<cfset local.thisEmailBody = Replace(local.thisEmailBody, "__blogURL__", local.getBlog.blogURL, "ALL")>
							</cfif>
						
						</cfif>
												
						<cfif arguments.insertUserFirstName>
							<cfset local.thisEmailBody = Replace(local.thisEmailBody, "__userFirstName__", local.getTOAddress.userFirstName, "ALL")>
						</cfif>		

						<cfif arguments.insertUserPassword>
							<cfset local.thisEmailBody = Replace(local.thisEmailBody, "__password__", local.getTOAddress.userPassword, "ALL")>
						</cfif>			
								
						<cfif arguments.insertUserEmail>
							<cfset local.thisEmailBody = Replace(local.thisEmailBody, "__email__", local.getTOAddress.userEmail, "ALL")>
						</cfif>
		
						<cfif arguments.insertConfirmationCode>
							<cfset local.thisEmailBody = Replace(local.thisEmailBody, "__confirmationCode__", local.getTOAddress.userConfirmationCode, "ALL")>
						</cfif>
					
					
						<cfif arguments.insertURL>
							<cfset local.thisEmailBody = Replace(local.thisEmailBody, "__URL__", variables.url, "ALL")>
						</cfif>					

						<cfif arguments.insertTITLE>
							<cfset local.thisEmailBody = Replace(local.thisEmailBody, "__TITLE__", variables.title, "ALL")>
						</cfif>
						
						
						<cfloop query="local.getTOAddress">
						
							<cfmail
						    	to 	     = "#userEmail#"
						    	cc 		 = "#local.CC#" 
						    	from 	 = "#local.getEmail.emailFrom#"
								subject  = "#local.getEmail.emailSubject#"
						    	type 	 = "html"
								username = "#variables.emailUsername#"
								server   = "#variables.emailServer#"
								port     = "#variables.emailServerPortSMTP#"
								usessl   = "#variables.emailServerSSL#"
								password = "#variables.emailPassword#">
								#local.thisEmailBody#	
					 		</cfmail>
					 
								 
							<!--- <cfoutput>userEmail: #userEmail#
								local.CC: #local.CC#
								local.getEmail.emailFrom: #local.getEmail.emailFrom#
								local.getEmail.emailSubject: #local.getEmail.emailSubject#
								local.getEmail.emailBody: #local.getEmail.emailBody#</cfoutput> --->
							<!--- // 400, 'Email : Sent', 'System sent user email', 1 --->
							<cfset local.logAction = logAction( actionID = 400, extra = arguments.emailID, blogID = arguments.blogID )>			 
					
						</cfloop>
				
					</cfif>
					<!--- end: Any TO User ID email(s) found? --->
	   
											
				    <cfset result.status = true />
   		
	  				<cfcatch>

						<cfset result.message = errorMessage( message = 'notify_post_mailtouser_error', error = variables.cfcatch)>
					<!--- // 405, 'Email : Error', 'Error encountered while sending email', 1 --->
						<cfset local.logAction = logAction( actionID = 105, extra = "userEmail: #arguments.userEmail# - userFirstName: #arguments.userFirstName# - userLastName: #arguments.userLastName# - userPassword = #arguments.userPassword# - userPasswordReminder: #arguments.userPasswordReminder#")>	
						<cfreturn representationOf(result.message).withStatus(500)>

					</cfcatch> 
		
				</cftry>    

		 		
				<cfset result.message = application.messages['notify_post_mailtouser_success']>
				
				<cfreturn representationOf(result).withStatus(200) />

			</cfcase>

			<cfcase value="sendEmailToAny">
				
				<cfparam name="arguments.emailSubject"    	default="#variables.title# : Contact Form Received" hint="Email Body">
				<cfparam name="arguments.emailFrom" 	   	default="#variables.supportEmail#" hint="Email From Address">
				<cfparam name="arguments.senderName" 	   	default="Support" hint="Used in subject">
				<cfparam name="arguments.TO"	 	        default="#variables.adminEmail#" hint="Email addresses TO recipient(s) - defaults to admin email">
				<cfparam name="arguments.CC"				default="" hint="Email addresses of CC recipient(s)">
		 		 
				<!--- :: init result structure --->	
				<cfset var result = StructNew() />
				<cfset var local  = StructNew() />
				<cfset result.status  	= false />

				<cftry>  
		 		
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
		 				<cfset result.message = application.messages['notify_post_mailtoany_success']>					
				    <cfset result.status = true />
		   		
		 		<cfcatch>

		 			<cfset result.message = errorMessage( message = 'notify_post_mailtoany_success', error = variables.cfcatch)>					
					
					<!--- // 405, 'Email : Error', 'Error encountered while sending email', 1 --->
					<cfset logAction( actionID = 105, extra = "userEmail: #arguments.userEmail# - userFirstName: #arguments.userFirstName# - userLastName: #arguments.userLastName# - userPassword = #arguments.userPassword# - userPasswordReminder: #arguments.userPasswordReminder#", errorCatch = variables.cfcatch, cgi = arguments.cgi )>	
					<cfreturn noData().withStatus(500)>	

				</cfcatch> 
				
			</cftry>   
		 		 												
		    
				<cfreturn representationOf(result).withStatus(200) />

			</cfcase>

		</cfswitch>
				
	</cffunction>

</cfcomponent>

