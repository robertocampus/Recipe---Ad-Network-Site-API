<cfcomponent extends="taffyAPI.base" taffy:uri="/contest/" hint="Return Contest Details.">

	<cffunction name="GET" access="public" hint="Return Current Contests Listing DATA" returntype="struct" output="false">

		<cfargument name="filters" type="struct" default="#StructNew()#" required="no" hint="Blog Listing Filters struct">
		<cfargument name="pagination"  type="struct" default="#StructNew()#" required="no" hint="Blog Listing Paging struct"> 
		<cfargument name="sponsorID" type="string" default="" required="no" hint="Sponsor ID">
		<cfargument name="contestIsVisible" type="string" required="no" default="1" hint="Show only visible contests/promotions">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />
		<cfset result['error']		= ''>

		<cfparam name="arguments.pagination.orderCol" default="C.contestID">
		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);

		</cfscript>

		<cftry> 

		    <cfquery datasource="#variables.datasource#" name="result.query" cachedwithin="#CreateTimeSpan(0,0,0,0)#">
				SELECT
					C.contestName,
					C.contestSlug,
					C.contestIsQuotaFilled,
					C.contestIsAvailable,
					C.contestWinnersCount,			
					P.prizeName,
					VR.contestRegionName,
					VC.contestTypeName,
					
					S.sponsorName,
					S.sponsorURL,
					
					CONCAT( CI.imagePath, '/', CI.imageName )			AS 'contest_FullSize_imageName',
					CONCAT( CI.imagePath, '/', CI.imageThumbFileName )	AS 'contest_Thumb_Image', 
					CONCAT( CI.imagePath, '/', CI.imageFileNameHalf )	AS 'contest_mini_Image',
				 
					CONCAT( SI.imagePath, '/', SI.imageName )			AS 'sponsor_FullSize_imageName',
					CONCAT( SI.imagePath, '/', SI.imageThumbFileName )	AS 'sponsor_Thumb_Image', 
					CONCAT( SI.imagePath, '/', SI.imageFileNameHalf )	AS 'sponsor_mini_Image', 

					CONCAT( PI.imagePath, '/', PI.imageName )			AS 'prize_FullSize_imageName',
					CONCAT( PI.imagePath, '/', PI.imageThumbFileName )	AS 'prize_Thumb_Image', 
					CONCAT( PI.imagePath, '/', PI.imageFileNameHalf )	AS 'prize_mini_Image',
					
					lcase(VC.contestTypeName) AS contestTypeName
			
			FROM contests C
			LEFT JOIN images 			 CI	 ON CI.entityID = C.contestID AND CI.entityTypeID = 5
			LEFT JOIN val_contesttype    VC  ON VC.contestTypeID = C.contestTypeID
			LEFT JOIN val_contestregion  VR  ON VR.contestRegionID = C.contestRegionID
			
			LEFT JOIN sponsors 	    S	     ON S.sponsorID = C.sponsorID
			LEFT JOIN images 			 SI	 ON SI.entityID = S.sponsorID AND SI.entityTypeID = 20

			LEFT JOIN prizes 			 P	 ON P.prizeID = C.prizeID
			LEFT JOIN images 			 PI	 ON PI.entityID = P.prizeID AND PI.entityTypeID=22
			
			WHERE C.active = 1
			 
				AND (  C.contestExpireDate >= DATE(NOW())  OR C.contestExpireDate IS null  )
				AND (  C.contestPublishDate <= DATE(NOW()) OR C.contestPublishDate IS null ) 
				
				<cfif isNumeric(arguments.sponsorID)>
					AND C.sponsorID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.sponsorID#">
				</cfif>
				
				<cfif isDefined("arguments.contestIsVisible")>
					AND C.contestIsVisible = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.contestIsVisible#">
				</cfif>

				<cfif StructCount(arguments.filters) GT 0>
				
					<cfloop collection="#arguments.filters#" item="thisFilter">
				 
					<!--- SIMPLE SEARCH on Item Title --->	
					<cfif thisFilter EQ "SearchText" AND TRIM(arguments.filters[thisFilter]) NEQ "">
						AND C.contestName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#arguments.filters[thisFilter]#%" /> 
					<!--- 	OR  itemText 	  LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#arguments.filters[thisFilter]#%" />  --->	
						
					<cfelseif thisFilter EQ "contestTypeID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
						AND C.contestTypeID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )

					<cfelseif thisFilter EQ "isNotExpired" AND TRIM(arguments.filters[thisFilter]) EQ 1>
						AND ( 
								C.contestExpireDate >= DATE(NOW())
							 OR C.contestExpireDate IS null 
							 )
							
					<cfelseif thisFilter EQ "isPublished" AND TRIM(arguments.filters[thisFilter]) EQ 1>
						AND ( 
								C.contestPublishDate <= DATE(NOW())
							 OR C.contestPublishDate IS null 
							 ) 

					<cfelseif thisFilter EQ "sponsorName" AND TRIM(arguments.filters[thisFilter] NEQ "")>
						AND S.sponsorName LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">
					</cfif>
				
				</cfloop>					
						
			</cfif>

			ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir#				
		        
		        LIMIT #arguments.pagination.offset#, #arguments.pagination.limit#

		</cfquery>
		
		<cfif result.query.recordCount EQ 0>

			<cfset result.message = application.messages['contest_get_found_error']>
		  	<cfreturn noData().withStatus(404)>
			
		</cfif>
		   
		<cfcatch>
			
			<!--- :: degrade gracefully :: --->
			<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>

			<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
			<cfset logAction( actionID = 661, extra = "method: /contest/GET", errorCatch = variables.cfcatch  )>	
		  	<cfreturn representationOf(result.message).withStatus(500)>

		</cfcatch>
		
	  </cftry> 

	  	<!--- //Valid contest details are found and listed --->
	  	<cfset result.message = application.messages['contest_get_found_success']>
	  	<cfset result.status = true>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="PUT" access="public" hint="Update Contest Winner Status" output="true">
		<cfargument name="functionName"			 type="string"  required="true" hint="function name to update contest details">
		<cfargument name="ContestWinnerID" 		 type="string" 	required="yes" hint="Contest Winner ID">
		<cfargument name="contestWinnerStatusID" type="string" 	required="no"  default="2" hint="0 : New / 1 : Notified / 2 : Pending Answer / 3: Pending Prize / 4: Pending Prize / 5 : Filled ">
		<cfargument name="ContestDeclineReasonID" 	type="string" 	required="no" default="6" hint="Contest Decline Reason ID">

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset var local  = StructNew() />
		<cfset result['status'] = false />
		<cfset result['message']	= "" />

    	<cfswitch expression= "#arguments.functionName#">

    		<cfcase value="updateContestWinnerStatus">
				<cftry>
				
			        <cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
			  			        
					<cfquery datasource="#variables.datasource#" name="result.query">

						UPDATE contestwinners
						   SET contestWinnerStatusID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.contestWinnerStatusID#">
			   			 WHERE contestWinnerID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.contestWinnerID#" list="yes"> )

					</cfquery>
					
			 			
						 
					<cfcatch>
				      	<!--- :: degrade gracefully :: --->
				      
				      	<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>
				       
				     	<!--- // 666, 'Database Error', 1 --->
					 	<cfset local.tmp = application.dataObj.logAction( actionID = 666,  extra = "method:/contest/PUT" ,errorCatch = variables.cfcatch  )>	
						<cfreturn representationOf(result.message).withStatus(500)>
					  
			        </cfcatch>
					
			    </cftry> 

				<cfset result.status  	= true />

				<!--- //Contest Winner Status Updated.Thank You --->
		  		<cfset result.message = application.messages["contest_put_updateContestWinnerStatus_success"]>	
				<!--- // 1116, 'Contest Winner Status Updated', 1 --->
				<cfset logAction( actionID = 1116, extra = "method:/contest/PUT" )>	

				<cfreturn representationOf(result).withStatus(200) />

    		</cfcase>

    		<cfcase value="updateIsViewed">

		  
				<cftry>
				
			        <cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
			  			        
					<cfquery datasource="#variables.datasource#" name="result.query">

						UPDATE contestwinners
						   SET isViewed = 1
			   			 WHERE contestWinnerID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.contestWinnerID#" list="yes"> )

					</cfquery>
					
			 			
						 
					<cfcatch>
				      	<!--- :: degrade gracefully :: --->
				      	<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				       
				     	<!--- // 666, 'Database Error', 1 --->
					 	<cfset logAction( actionID = 666, errorCatch = variables.cfcatch,extra = "method:/contest/PUT"  )>	
						<cfreturn representationOf(result.message).withStatus(500)>
					  
			        </cfcatch>
						
			    </cftry> 


				<cfset result.status  	= true />
				<!--- //Contest winner has viewed promotion invitation. --->
				<cfset result.message   = application.messages['contest_put_updateIsViewed_success']>
				<!--- // 1122, 'Contest Winner : Viewed', 'Contest winner has viewed promotion invitation.', 1 --->
				<cfset logAction( actionID = 1122, extra = "method:/contest/PUT" )>	

				<cfreturn representationOf(result).withStatus(200) />

    		</cfcase>

    		<cfcase value="updateContestDeclineReasonID">
    			
				<cftry>
				
			       	<cfquery datasource="#variables.datasource#" name="result.query">

						UPDATE contestwinners
						   SET contestdeclinereasonID = 1
			   			 WHERE contestWinnerID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.contestWinnerID#" list="yes"> )
			   			 
					</cfquery>
					
					<cfcatch>

						<!--- :: degrade gracefully :: --->
				      	<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>

						<!--- // 666, 'Database Error', 1 --->
						<cfset logAction( actionID = 666, errorCatch = variables.cfcatch,extra="method:/contest/PUT")>	
											  
						<cfreturn representationOf(result.message).withStatus(500)>

			        </cfcatch>
					
			    </cftry> 


				<cfset result.status  	= true />
				<cfset result.message   = application.messages['contest_put_updateContestDeclineReasonID_success']>
				<!--- // 1124, 'Contest Winner : Declined', 'Contest winner has declined promotion invitation.', 1 --->

				<cfset logAction( actionID = 1124, extra="method:/contest/PUT")>

				<cfreturn representationOf(result).withStatus(200) />

    		</cfcase>
    		
    	</cfswitch>		

	</cffunction>

</cfcomponent>