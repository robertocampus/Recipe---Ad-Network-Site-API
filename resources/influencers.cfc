<cfcomponent extends="taffyAPI.base" taffy:uri="/influencers/" output="true" hint="influencers is used to get the ifluencers details">

	<cffunction name="GET" access="public" hint=" Influencer Listing DATA using filters and paging" returntype="struct" output="true">
		<cfargument name="filters" 		type="struct" default="#StructNew()#" required="no" hint="Listing Filters struct">
		<cfargument name="pagination"   type="struct" default="#StructNew()#" required="no" hint="Listing Paging struct">
        <cfargument name="cache"   		type="string" default="1" 		 	  required="no" hint="Query Cache Lenght">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status'] = false>
		<cfset result['message'] = "">

		<cfparam name="arguments.pagination.orderCol" 		default="u.userID"/>
		<cfparam name="arguments.pagination.isForceProfile" default="1"/>		
  		
		<cftry>
			<cfset arguments.pagination = checkPagination(arguments.pagination)>

	        <cfquery datasource="#variables.datasource#" name="result.query">
	 			SELECT SQL_CALC_FOUND_ROWS
					u.userFirstName
					,u.userLastName
					,u.userID
					,u.userEmail
					,CASE u.userGender
						WHEN '0' THEN 'N/A'	
						WHEN 'M' THEN 'Male'
						WHEN 'F' THEN 'Female'
					END AS userGenderName
					,u.userCity 
					,vs.stateName 
					,c.countryFullName
					
					,e.count AS 'popularity'
					
					,CONCAT( i.imagePath, '/', i.imageName ) AS 'user_FullSize_Image'
					,CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'user_Thumb_Image'
					,CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'user_mini_Image'
					,(SELECT max(meta_value) FROM users_meta WHERE meta_key = 'user_total_followers' AND userID = u.userID ) AS 'user_total_followers'
					,(SELECT max(meta_value) FROM users_meta WHERE meta_key = 'user_total_activity'  AND userID = u.userID ) AS 'user_total_activity'
					,(SELECT max(meta_value) FROM influencers_meta  WHERE meta_key = 'status_visibility'  AND userID = u.userID ) AS 'status_visibility'
					,(SELECT max(meta_value) FROM influencers_meta  WHERE meta_key = 'status_availability'  AND userID = u.userID ) AS 'status_availability'
					,(SELECT max(meta_value) FROM influencers_meta  WHERE meta_key = 'score'  AND userID = u.userID ) AS 'score'
					,(SELECT count(userID) FROM users_follow WHERE entityID = u.userID AND entitytypeID = 4 AND followStatus = 1 ) AS 'influencer_totalFollowers'

				FROM users u 
				
				LEFT JOIN val_countries c ON c.countryID = u.userCountryID 
				LEFT JOIN val_states vs ON vs.stateID = u.userStateID				
				LEFT JOIN images i ON i.entityID = u.userID AND i.entityTypeID = 4 AND i.active = 1
				LEFT JOIN entityViewsCount e ON e.entityID = u.userID AND e.entityTypeID = 4 
				
				WHERE 1 = 1 

				AND u.active = <cfqueryparam value="1" cfsqltype="cf_sql_integer">			
				AND u.isInfluencer = <cfqueryparam value="1" cfsqltype="cf_sql_integer">
				AND u.influencerStatusID = <cfqueryparam value="3" cfsqltype="cf_sql_integer">
				AND u.userID IN ( SELECT userID FROM influencers_meta WHERE meta_key = 'status_visibility' AND meta_value = 1)

				<!--- ADD FILTERS TO QUERY  --->
				<cfif StructCount(arguments.filters) GT 0>

					<cfloop collection="#arguments.filters#" item="thisFilter">

						<cfif thisFilter EQ "keywords" AND TRIM(arguments.filters[thisFilter]) NEQ "">
									
						AND ( 
							
							<!--- the first condition must not have an OR. All subsequent conditions must have an OR. --->
							
							<!--- Search in blogTitle --->
							<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">

								<cfif listFirst(arguments.filters[thisFilter]) NEQ thisKeyword>
									OR
								</cfif>
								u.userFirstName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
								
							</cfloop>

							<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">

								OR u.userLastName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
								
							</cfloop>	

							<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">

								OR u.userCity LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
								
							</cfloop>

							<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">

								OR u.userAbout LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
							
							</cfloop>


							OR u.usercountryID IN (
									SELECT countryID 
										FROM val_countries vc 
										WHERE 1=1
											AND
											<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
												<cfif listFirst(arguments.filters[thisFilter]) NEQ thisKeyword>
													OR
												</cfif>
												vc.countryFullName LIKE '%#thisKeyword#%'
											</cfloop>
										)

							OR u.userID IN  ( 
										SELECT tg.userID FROM tags AS t 
												INNER JOIN tagging AS tg 
												ON tg.tagID = t.tagID AND tg.entityTypeID = 30
												WHERE 1=1
													AND
												<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">

													<cfif listFirst(arguments.filters[thisFilter]) NEQ thisKeyword>
														OR
													</cfif>
													t.tagName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
												</cfloop>
											)


							)
						</cfif>

					</cfloop>	

				</cfif>
				GROUP BY u.userID
				ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir# limit #arguments.pagination.offset#, #arguments.pagination.limit# 
	          
			</cfquery>
			
			<cfquery datasource="#variables.datasource#" name="local.query">
				SELECT FOUND_ROWS() AS total_count;
			</cfquery>	
			
			<cfset result.total_rows = local.query.total_count>
	 	    
		 	<cfcatch>
				
				<!--- :: degrade gracefully :: --->
				
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: getPublicUsers", errorCatch = variables.cfcatch  )>	
			  	<cfreturn representationOf(result.message).withStatus(500)>
			</cfcatch>
			
	  </cftry>
	  
	  	<cfset result.status = true>
		<cfset result.message = application.messages['influencers_get_found_success']>

		<cfset logAction( actionID=101 , extra = "method: /influencers/GET" )>
		<cfreturn representationOf( result ).withStatus(200)/>

		<cfreturn result />

	</cffunction>

</cfcomponent>
