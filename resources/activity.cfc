<cfcomponent extends="taffyAPI.base" taffy:uri="/activity/" hint="Return activity Details.">

	<cffunction name="GET" access="public" hint="Return contest winner activity DATA by ID"  output="false">

		<cfargument name="functionName"     type="string"   required="true">
		<cfargument name="attributes"       type="string"   required="true">
		
		<cfset structAppend( arguments, deserializeJson( arguments.attributes ) )>
		<cfset result = structNew() >
		<cfset result['status']  	= false />
		<cfset result['error'] = false >
		<cfset result['message'] = ''>
		<cfset result['errors'] = "" >
		<cfset result['errorsforlog'] = "" >

		<cfswitch expression="#arguments.functionName#">

			<cfcase value="getContestWinnerActivityByID">
				
				<cfif NOT LEN(TRIM(arguments.contestWinnerID)) >
					
					<cfset result['errors'] = listAppend(result['errors'], "contestWinnerID")>
					<cfset result['errorsforlog'] = listAppend(result['errorsforlog'], "contestWinnerID: #arguments.contestWinnerID#")>

				</cfif> 

				<cfif ( ListLen(result['errors']) GT 0 ) >
					
					<cfset result['error'] = true> 
					<!--- //User submitted invalid input in the form. --->
					<cfset result['message'] = application.messages['activity_get_getcontestwinneractivity_error']>
					
					<!--- Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1 --->
					<cfset logAction( actionID = 312, extra = result['errorsforlog'])>
					
					<cfreturn representationOf(result).withStatus(401)>

				<cfelse>
			
					<cftry>	
						<cfquery datasource="#variables.datasource#" name="result.query"><!---  cachedwithin="#CreateTimeSpan(0,1,0,0)#" --->
							SELECT   
								CA.*,
								CAT.contestActivityTypeName,
								CAT.contestActivityTypeDescription
														
							FROM contest_activity CA
							 	LEFT JOIN val_contestactivitytype CAT ON CAT.contestActivityTypeID = CA.contestActivityTypeID
							 
							WHERE 1 = 1
							
							AND CA.contestWinnerID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestWinnerID#">
							 
						</cfquery>
							 
						<cfif result.query.recordCount EQ 0>
							<!--- //OOPS!...Contest winner details not  found.The last operation was not completed. --->
							<cfset result.message = application.messages['activity_get_getcontestwinneractivitybyid_error']>
							<!--- Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1 --->
							<cfset logAction( actionID = 312, extra = result['errorsforlog'])>

							<cfreturn noData().withStatus(404)>

						</cfif>
						 	 
						<cfcatch>

							<!--- :: degrade gracefully :: --->
							
							<cfset result.message = errorMessage(message='database_query_error', error = variables.cfcatch)>

							<!--- // 666, 'Database Error', 1 --->
							<cfset logAction( actionID = 666, userID = 1, errorCatch = variables.cfcatch,extra="method:/activity/GET"  )>	

							<cfreturn representationof( result.message ).withStatus(500)>


						</cfcatch>

					</cftry> 

					<cfset result.status  	= true />
					<!--- //Contest winner details found.The last operation was completed. --->
					<cfset result.message = application.messages['activity_get_getcontestwinneractivitybyid_success']>
					<cfreturn representationOf(result).withStatus(200) />

				</cfif> 

			</cfcase>

			<cfcase value="getContestWinnerActivityUserByID">
				
				
					
				<!--- :: init result structure --->	

			  	<cfparam name="contestID" default="">

				<cfif NOT LEN(TRIM(arguments.userID)) >
					
					<cfset result['errors'] = listAppend(result['errors'], "userID")>
					<cfset result['errorsforlog'] = listAppend(result['errorsforlog'], "userID: #arguments.userID#")>

				</cfif> 

				<cfif ( ListLen(result['errors']) GT 0 ) >
					
					<cfset result['error'] = true> 
					<cfset result['message'] = application.messages['activity_get_getcontestwinneractivity_error']>
					<!--- Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1 --->
					<cfset logAction( actionID = 312, extra = result['errorsforlog'])>
					
					<cfreturn representationOf(result).withStatus(401)>

				<cfelse>

					<cftry>
						<cfquery datasource="#variables.datasource#" name="result.query"><!---  cachedwithin="#CreateTimeSpan(0,1,0,0)#" --->
							SELECT   
								CS.contestName,
						        CS.contestID,
						        CW.contestWinnerStatusID,
						        VC.contestWinnerStatusName,
						        CA.*,
								CAT.contestActivityTypeName,
								CAT.contestActivityTypeDescription,
								S.sponsorName,
								(SELECT count(*) FROM  contest_activity CAA WHERE CAA.userID = CA.userID AND CAA.contestID = CA.contestID ) AS activityCount 
														
							FROM contestwinners CW
							 	LEFT JOIN contest_activity CA ON CA.contestWinnerID = CW.contestWinnerID 
							 	LEFT JOIN contestrun CR ON CR.contestRunID = CW.contestRunID
							 	LEFT JOIN val_contestactivitytype CAT ON CAT.contestActivityTypeID = CA.contestActivityTypeID
							 	LEFT JOIN contests CS ON CS.contestID = CW.contestID
							 	LEFT JOIN blogs B ON B.blogID = CA.blogID
							 	LEFT JOIN users U ON U.userID = CA.userID
							 	LEFT JOIN sponsors S ON S.sponsorID = CS.sponsorID
							 	LEFT JOIN val_contestwinnerstatus VC ON VC.contestWinnerStatusID = CW.contestWinnerStatusID
							 
							WHERE 1 = 1
							
							AND CW.userID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.userID#">
							
							<cfif isDefined("arguments.contestID")>
								AND CW.contestID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestID#">
							</cfif>	
							
							ORDER BY CS.contestID DESC, CA.contestActivityDate DESC
							 
						</cfquery>
							 
						   
						 	 
						<cfcatch>
							<!--- :: degrade gracefully :: --->
							
							<cfset result.message = errorMessage(message='database_query_error', error = variables.cfcatch)>

							<!--- // 666, 'Database Error', 1 --->
							<cfset logAction( actionID = 666, errorCatch = variables.cfcatch,extra="method:/activity/GET"  )>	

							<cfreturn representationof( result.message ).withStatus(500)>
						  
				        </cfcatch>
							
					</cftry> 

					<cfset result.message = application.messages['activity_get_getcontestwinneractivityuserbyid_error']>

					<cfif result.query.recordCount GT 0> 	 
						<cfset result.status  	= true />
						<!--- //Contest winner details found.The last operation was completed. --->
						<cfset result.message = application.messages['activity_get_getcontestwinneractivityuserbyid_success']>
					</cfif>

					<cfreturn representationOf(result).withStatus(200) />

				</cfif>

			</cfcase>

			<cfcase value="getUserActivityCount">

 			
				<cfif NOT LEN(TRIM(arguments.userID)) >
					
					<cfset result['errors'] = listAppend(result['errors'], "userID")>
					<cfset result['errorsforlog'] = listAppend(result['errorsforlog'], "userID: #arguments.userID#")>

				</cfif> 

				<cfif ( ListLen(result['errors']) GT 0 ) >
					
					<cfset result['error'] = true> 
					
					<!--- Log: 312, 'Comment: Invalid Input', 'User submitted invalid input in the comment form.', 1 --->
					<cfset result.message = application.messages['activity_get_getUserActivityCount_error']>
					<cfset logAction( actionID = 312, extra = result['errorsforlog'])>
					
					<cfreturn representationOf(result).withStatus(401)>

				<cfelse>
			  
					<cftry>
					
						<cfquery datasource="#variables.datasource#" name="result.query">

							SELECT count(*) AS activityCount
							FROM contest_activity  
							WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.userID#">

						</cfquery>		
					 
				
						<cfcatch>
						<!--- :: degrade gracefully :: --->
							<!--- //Error while executing the query.Please try again later. --->
							<cfset result.message = errorMessage(message='database_query_error', error = variables.cfcatch)>

							<!--- // 666, 'Database Error', 1 --->
							<cfset logAction( actionID = 666, errorCatch = variables.cfcatch,extra="method:/activity/GET")>	

							<cfreturn representationof( result.message ).withStatus(500)>

						</cfcatch>

					</cftry>

					<cfset result.message = application.messages['activity_get_getUserActivityCount_success']>
					<cfset result.status = true />
					<cfreturn representationOf(result).withStatus(200) />

				</cfif>

			</cfcase>

		</cfswitch>

	</cffunction>

	<cffunction name="POST" access="public" hint="Insert contest winner record" returntype="struct" output="true">

		<cfargument name="contestWinnerID" 		 type="string" 	required="yes" 				hint="Contest Winner ID">
		<cfargument name="contestActivityTypeID" type="string" 	required="yes" 				hint="">
		<cfargument name="contestActivityURL"	 type="string" 	required="yes" 				hint="Contest Activity URL">
		<cfargument name="contestActivityText"	 type="string" 	required="no" 	default="" 	hint="Contest Notes (text)">
		<cfargument name="contestID"			 type="string" 	required="no" 	default="0"	hint="Contest ID">
		<cfargument name="contestRunID"			 type="string" 	required="no" 	default="0"	hint="Contest Run ID">
		<cfargument name="blogID"				 type="string" 	required="no" 	default="0"	hint="Blog ID">	
		<cfargument name="userID"				 type="string" 	required="no"  	default="0" hint="User ID">
		
 	
 		<!--- :: init result structure --->	
		<cfset var result 	 = StructNew() />
		<cfset var local  	 = StructNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>
		
		<cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
  			
		<cftry> 
		
		    <cfquery datasource="#variables.datasource#" name="local.insertcontestrun">
                INSERT INTO contest_activity
                	   (
						contestWinnerID,		
						contestActivityTypeID,
						contestActivityURL,
						contestActivityText,
						<cfif isDefined("arguments.contestID")>
							contestID,
						</cfif>
						<cfif isDefined("arguments.contestRunID")>
							contestRunID,
						</cfif>
						<cfif isDefined("arguments.blogID")>
							blogID,
						</cfif>
						<cfif isDefined("arguments.userID")>
							userID,
						</cfif>
						contestActivityDate
						)
				VALUES (  
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestWinnerID#">, 
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestActivityTypeID#">, 
						<cfqueryparam cfsqltype="cf_sql_string"    value="#left(arguments.contestActivityURL,255)#">, 
						<cfqueryparam cfsqltype="cf_sql_string"      value="#arguments.contestActivityText#">,

						<cfif isDefined("arguments.contestID")>
							<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestID#">,
						</cfif>

						<cfif isDefined("arguments.contestRunID")>
							<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestRunID#">,
						</cfif>

						<cfif isDefined("arguments.blogID")>
							<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.blogID#">,
						</cfif>

						<cfif isDefined("arguments.userID")>
							<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.userID#">,
						</cfif>

						<cfqueryparam cfsqltype="cf_sql_timestamp"   value="#local.timeStamp#">
						)
             </cfquery>		
			
            <cfquery datasource="#variables.datasource#" name="local.getLast"> 
            	SELECT LAST_INSERT_ID() AS ID
            </cfquery>

 		
			<cfcatch>

				<!--- // 1127, Contest:Error on Insert Activity, Error encountered while inserting contest activity., 1 --->
				<cfset logAction( actionID = 1127, userID = 1, errorCatch = variables.cfcatch, extra = "method:/activity/POST")>	

				<!--- //Error while executing the query.Please try again later. --->
				<cfset result.message = errorMessage(message='database_query_error', error = variables.cfcatch)>

				<cfreturn representationOf(result.message).withStatus(500)>

			</cfcatch> 

 		</cftry>
       
        <cfset result.contestActivityID = local.getLast.ID />			
		
		<!--- //Contest winner activity details has been added successfully.Thank You --->
		<cfset result.message = application.messages['activity_post_add_success']>
		<!--- // 1126, Contest: Insert Activity, Contest winner activity inserted successfully., 1 --->
        <cfset logAction( actionID = 1126,  extra = "method:/activity/POST")>	
    
        <cfset result.status = true />

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>