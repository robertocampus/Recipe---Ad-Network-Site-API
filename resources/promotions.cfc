<cfcomponent extends="taffyAPI.base" taffy:uri="/promotions/" hint="Return Contest Details.">
	
	<cffunction name="GET" access="public" hint="Return Contests Listing DATA using filters and paging" output="false">
		<cfargument name="filters" type="struct" default="#StructNew()#" required="no" hint="Blog Listing Filters struct">
		<cfargument name="pagination"  type="struct" default="#StructNew()#" required="no" hint="Blog Listing Paging struct">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result.status  	= false />
		<cfset result.message 	= "" />

		<cfparam name="arguments.pagination.orderCol" default="C.contestID">

		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);

		</cfscript>

		<cftry>

		    <cfquery datasource="#variables.datasource#" name="result.query">
				SELECT 	SQL_CALC_FOUND_ROWS
					C.*,
					P.*,
					VR.*,
					VC.*,
					
					S.sponsorName,
					S.sponsorURL,
					S.sponsorEmail,
					S.sponsorTweeterUsername,
					S.sponsorFacebook,
					S.sponsorContactName,
					S.sponsorCreateDate,
					S.sponsorDescription,
					
					CONCAT( CI.imagePath, '/', CI.imageName )			AS 'contest_FullSize_imageName',
					CONCAT( CI.imagePath, '/', CI.imageThumbFileName )	AS 'contest_Thumb_Image', 
					CONCAT( CI.imagePath, '/', CI.imageFileNameHalf )	AS 'contest_mini_Image',
				 
					CONCAT( SI.imagePath, '/', SI.imageName )			AS 'sponsor_FullSize_imageName',
					CONCAT( SI.imagePath, '/', SI.imageThumbFileName )	AS 'sponsor_Thumb_Image', 
					CONCAT( SI.imagePath, '/', SI.imageFileNameHalf )	AS 'sponsor_mini_Image', 

					CONCAT( PI.imagePath, '/', PI.imageName )			AS 'prize_FullSize_imageName',
					CONCAT( PI.imagePath, '/', PI.imageThumbFileName )	AS 'prize_Thumb_Image', 
					CONCAT( PI.imagePath, '/', PI.imageFileNameHalf )	AS 'prize_mini_Image',
					
					lcase(VC.contestTypeName) AS contestTypeName,
					( SELECT count(*) FROM comments CM WHERE CM.entityID = C.contestID AND CM.entityTypeID = 5 AND CM.active = 1 ) as CommentCount,
						
				    CASE 
				        WHEN ((datediff(DATE(NOW()), contestExpireDate))<1) THEN 0
				        ELSE 1
					END AS isExpired 
					,e.count AS 'popularity'
			
				FROM contests C
				INNER JOIN sponsors S ON S.sponsorID = C.sponsorID
				LEFT JOIN images SI ON SI.entityID  = S.sponsorID AND SI.entityTypeID = 20 AND SI.active = 1

				LEFT JOIN val_contesttype    VC ON VC.contestTypeID = C.contestTypeID				
				LEFT JOIN val_contestregion  VR ON VR.contestRegionID = C.contestRegionID
				LEFT JOIN images 			 CI	ON CI.entityID = C.contestID AND CI.entityTypeID = 5


				LEFT JOIN prizes P  ON  P.prizeID  = C.prizeID
				LEFT JOIN images PI ON PI.entityID = P.prizeID AND PI.entityTypeID = 22 AND PI.active = 1
				LEFT JOIN entityViewsCount e ON e.entityID 	= S.sponsorID	AND e.entitytypeID = 20
				WHERE C.active = 1
				
				<!--- ADD FILTERS TO QUERY  --->
				<cfif StructCount(arguments.filters) GT 0>
					
						<cfloop collection="#arguments.filters#" item="thisFilter">					 

						<!--- SIMPLE SEARCH on contest keywords --->
						<cfif	thisFilter EQ "keywords" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								
							AND ( 
								
									<!--- Search in contestName --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
										
										<cfif listFirst(arguments.filters[thisFilter]) NEQ thisKeyword>
											OR
										</cfif>
										C.contestName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
									</cfloop>

									<!--- Search over contestDescription --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
										OR C.contestDescription LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
									</cfloop>
									
									<!--- Search over sponsorName --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
										OR S.sponsorName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
									</cfloop>								
									
								)
							
						<cfelseif thisFilter EQ "contestTypeID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND C.contestTypeID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes">)

						<cfelseif thisFilter EQ "isNotExpired" AND TRIM(arguments.filters[thisFilter]) EQ 1 AND arguments.filters[thisFilter] NEQ 0 >
							AND ( 
									C.contestExpireDate >= DATE(NOW())
								 OR C.contestExpireDate IS null 
								 )
								
						<cfelseif thisFilter EQ "isPublished" AND TRIM(arguments.filters[thisFilter]) EQ 1 AND arguments.filters[thisFilter] NEQ 0 >
							AND ( 
									C.contestPublishDate <= DATE(NOW())
								 OR C.contestPublishDate IS null 
								 ) 

						<cfelseif thisFilter EQ "contestIsVisible" AND TRIM(arguments.filters[thisFilter]) EQ 1>
							AND C.contestIsVisible = 1  

						<cfelseif thisFilter EQ "userID" AND TRIM(arguments.filters[thisFilter]) NEQ ''>
							AND S.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "sponsorID" AND TRIM(arguments.filters[thisFilter]) NEQ ''>
							AND S.sponsorID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">
							
						<!--- OTHER FLAGS --->
						<cfelseif arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
							AND C.#thisFilter# = #val(arguments.filters[thisFilter])#
						</cfif>
					
					</cfloop>					
							
				</cfif>

				ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir#				
		        
		        LIMIT #arguments.pagination.offset#, #arguments.pagination.limit#
			</cfquery>

			<cfquery datasource="#variables.datasource#" name="result.rows">
				SELECT FOUND_ROWS() AS total_count;
			</cfquery>
		   
		  	<cfcatch>				
				<!--- :: degrade gracefully :: --->
				<cfset result.message = error.message(message = 'database_query_error')>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /promotions/ GET", errorCatch = variables.cfcatch  )>	
			  
			  	<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
		
	    </cftry>

	    <cfset result.status  	= true />
	    <cfset result.message = application.messages['promotions_get_found_success'] />

	  	<cfset local.tmp = logAction( actionID = 201, extra = "method: /promotions/ GET"  )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>	

</cfcomponent>