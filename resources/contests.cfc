<cfcomponent extends="taffyAPI.base" taffy:uri="/contests/" hint="Return Contest Details.">

	<cffunction name="GET" access="public" hint="Return contest winner DATA using filters and paging" returntype="struct" output="true">
		<cfargument name="functionName"		type="string"   required="true">
		<cfargument name="contestID"		type="string"	required="no" hint="Contest ID">
		<cfargument name="contestWinnerID"	type="string"	required="no" hint="Contest Winner ID">
		<cfargument name="blogID"			type="string"	required="no" hint="Contest Blog ID">
		<cfargument name="userID"			type="string"	required="no" hint="Contest User ID">
		<cfargument name="contestTypeID" 	type="string"	required="no" hint="Contest Type ID">
		
		<cfset var result = StructNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>

		<cfswitch expression="#arguments.functionName#">

			<cfcase value="getContestWinners">

			  
				<cftry>
				
					<cfquery datasource="#variables.datasource#" name="result.query"><!---  cachedwithin="#CreateTimeSpan(0,1,0,0)#" --->

						SELECT   
							CW.contestID,
							CW.contestWinnerStatusID,
							CR.contestRunID,
							CR.contestRunDate,
							CR.active,
							CS.emailID,
							CS.emailID_participantConfirmation,
							CS.emailID_participantCompleted,
							CS.contestIsQuotaFilled,
							CS.contestIsAvailable,
							B.blogTitle,
							B.blogID,
							B.blogURL,
							U.userID,
							U.userFirstName,
							U.userLastName,
							U.userEmail,
							U.username,
							( SELECT count(*) FROM contestrun WHERE contestID = CW.contestID ) as contestRunCountPos,
							S.sponsorName,
							CS.contestName,
							CS.contestWinnerPickDate
						FROM contestwinners CW
						LEFT JOIN contestrun CR ON CR.contestRunID = CW.contestRunID
						LEFT JOIN contests CS ON CS.contestID = CW.contestID
						LEFT JOIN blogs B ON B.blogID = CW.blogID
						LEFT JOIN users U ON U.userID = CW.userID
						LEFT JOIN sponsors S ON S.sponsorID = CS.sponsorID
						
						WHERE 1 = 1
						
						<cfif isDefined("arguments.contestID")>
							AND CW.contestID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestID#">
						</cfif>
						
						<cfif isDefined("arguments.contestWinnerID")>
							AND CW.contestWinnerID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestWinnerID#">
						</cfif>
						
						<cfif isDefined("arguments.blogID")>
							AND CW.blogID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.blogID#">
						</cfif>
						
						<cfif isDefined("arguments.userID")>
							AND CW.userID = <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.userID#">
						</cfif>
						
						<cfif isDefined("arguments.contestTypeID")>
							AND CS.contestTypeID IN ( <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestTypeID#" list="yes"> )
						</cfif>
						
												
					</cfquery>
						 
					   
					 	 
					<cfcatch>
				      	<!--- :: degrade gracefully :: --->
				      
				      	<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				       
				     	<!--- // 666, 'Database Error', 1 --->
					 	<cfset logAction( actionID = 666, userID = 1, errorCatch = variables.cfcatch ,extra="method:/contests/GET")>	
						<cfreturn representationOf( result.message ).withStatus(500)>

			        </cfcatch>
					
			    </cftry> 

				<cfset result.status  	= true />
				<cfset result.message = application.messages['contests_get_getContestWinners_success']>
				<cfreturn representationOf(result).withStatus(200) />
				
			</cfcase>

			<cfcase value="getUserContests">

				<cftry>
				
					<cfquery datasource="#variables.datasource#" name="result.query"><!---  cachedwithin="#CreateTimeSpan(0,1,0,0)#" --->
							
						SELECT DISTINCT CW.contestID, CS.contestName		
						FROM contestwinners CW
						LEFT JOIN contests CS ON CS.contestID = CW.contestID
						
						WHERE  CW.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
						
						<cfif isDefined("arguments.contestTypeID")>
							AND CS.contestTypeID IN ( <cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestTypeID#" list="yes"> )
						</cfif>
						
					</cfquery>
					
				   
					<cfcatch>
						<!--- :: degrade gracefully :: --->
						
						<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>
						<!--- // 666, 'Database Error', 1 --->
						<cfset logAction( actionID = 666, extra="method:/contests/GET", errorCatch = variables.cfcatch  )>	
						<cfreturn representationOf( result.message ).withStatus(500)>

					</cfcatch>
					
			    </cftry> 

				
				<cfset result.status = true />
				<cfset result.message = application.messages['contests_get_getUserContests_success']>
				<cfreturn representationOf(result).withStatus(200) />

			</cfcase>

		</cfswitch>

	</cffunction>


	<cffunction name="POST" access="public" hint="Insert contest winner record" returntype="struct" output="true">

		<cfargument name="contestID"			 type="string" 	required="yes" hint="Contest ID">
		<cfargument name="contestRunID"			 type="string" 	required="yes" hint="Contest Run ID">
		<cfargument name="blogID"				 type="string" 	required="yes" hint="Blog ID">	
		<cfargument name="userID"				 type="string" 	required="no"  default="0" hint="User ID">
		<cfargument name="contestWinnerStatusID" type="string" 	required="no"  default="2" hint="0 : New / 1 : Notified / 2 : Pending Answer / 3: Pending Prize / 4: Pending Prize / 5 : Filled ">
		
 	
 		<!--- :: init result structure --->	
		<cfset var result 	 = StructNew() />
		<cfset var local  	 = StructNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>
		
		<cftry> 

		    <cfquery datasource="#variables.datasource#" name="local.insertcontestrun">
                INSERT INTO contestwinners
                	   (
						contestID,		
						contestRunID,	
						blogID,
						userID,
						contestWinnerStatusID,
						active				
						)
				VALUES (  
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestID#">, 
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestRunID#">, 
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.blogID#">, 
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.userID#">, 
						<cfqueryparam cfsqltype="cf_sql_integer"   value="#arguments.contestWinnerStatusID#">, 
						1	
						)
             </cfquery>		
			
            <cfquery datasource="#variables.datasource#" name="local.getLast"> 
            	SELECT LAST_INSERT_ID() AS ID
            </cfquery>

	    		
 		
			<cfcatch>
			
				<!--- // 1113, 'Error: Insert Contest Winner', 'Error encountered while inserting contest winner', 1 --->
				<cfset logAction( actionID = 1111, extra = "method:/contests/POST", errorCatch = variables.cfcatch)>	
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf( result.message ).withStatus(500)>

			</cfcatch> 

 		</cftry>
       
        <cfset result.ContestWinnerID = local.getLast.ID />			
			
		<!--- // 1112, 'Contest Winner Inserted', 'Contest winner was inserted', 1 --->
        <cfset logAction( actionID = 1112,extra = "method:/contests/POST")>

    	<cfset result.message=application.messages['contests_post_addwinner_success']>
        <cfset result.status = true />

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>
	
</cfcomponent>