<cfcomponent extends="taffyAPI.base" taffy:uri="/sponsors" hint="sponsors used to get sponsors">

	<!--- Method :: GET --->
	<cffunction name="GET" access="public" hint="Return Public Sponsors Listing DATA using filters and pagination" output="true">
		<cfargument name="filters" 		type="struct" default="#StructNew()#" required="no" hint="Sponsor Listing Filters struct">
		<cfargument name="pagination"   type="struct" default="#StructNew()#" required="no" hint="Sponsor Listing pagination struct">        
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result.status  	= false />
		<cfset result.message 	= "" />

		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);
		</cfscript>
  		
		<cftry>
		
	        <cfquery datasource="#variables.datasource#" name="result.query">
	 			SELECT 	SQL_CALC_FOUND_ROWS
					 s.sponsorID 
					,s.sponsorName
					,s.sponsorSlug
					,s.sponsorURL
					,s.sponsorEmail
					,s.sponsorTweeterUsername
					,s.sponsorFacebook
					,s.sponsorInstagram
					,s.sponsorPinterest
					,s.sponsorGooglePlus
					,s.sponsorContactName
					,s.sponsorCreateDate
					,s.sponsorUpdateDate
					,s.sponsorText
					,s.sponsorDescription
					,s.sponsorAboutShort
					,s.sponsorIsBrandPage
					,s.sponsorCity				
					,s.sponsorZip				
					,s.userID				
					,s.active

					,(
						SELECT meta_value
							FROM sponsors_meta 
						WHERE meta_key = 'sponsors_total_followers' AND sponsorID = s.sponsorID
					) AS total_followers
					
					,CONCAT( i.imagePath, '/', i.imageName ) AS 'sponsor_FullSize_Image'
					,CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'sponsor_Thumb_Image'
					,CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'sponsor_mini_Image'
					
					,c.countryFullName
					,st.stateName
					
					,vsc.sponsorCategoryName				
					
					<!---(SELECT COUNT(*) from contests WHERE contests.sponsorID = s.sponsorID AND contests.active = 1) AS sponsor_total_contests,--->
					
					<!---(SELECT COUNT(*) from friends WHERE friends.friendUserID = s.userID) AS sponsor_total_friends,--->
					
					,( SELECT count(*) FROM items it WHERE it.userID = s.userID AND it.active = 1 AND it.itemIsPublished = 1 AND it.itemTypeID = 7 AND ( 
							it.itemPublishDate <= now() OR it.itemPublishDate IS null ) AND ( it.itemExpireDate >= now() OR it.itemExpireDate IS null )
					) as totalPosts
					
					,( SELECT count(*) FROM contests ct WHERE ct.sponsorID = s.sponsorID AND ct.active = 1 AND ct.contestPublishDate <= now() ) as totalPromotions
					,( SELECT count(*) FROM friends f WHERE f.friendStatusID = 2 AND f.active =1 AND (f.userID = s.userID OR f.friendUserID = s.userID) ) as totalFriends
					,(SELECT GROUP_CONCAT(tagName) FROM tags WHERE tagID IN(SELECT tagID FROM tagging WHERE entityID = s.sponsorID AND entityTypeID = 20)) AS tags			
					,e.count AS 'popularity'
					,(SELECT count(userID) FROM users_follow WHERE entityID = s.sponsorID AND entitytypeID = 20  AND followStatus = 1) AS 'sponsor_totalFollowers'
				FROM sponsors s
				
				LEFT JOIN images i on i.entityID = s.sponsorID	AND i.entitytypeID = 20 AND i.active = 1
				LEFT JOIN val_countries c ON c.countryID = s.sponsorCountryID
				LEFT JOIN val_states st ON st.stateID = s.sponsorStateID
				LEFT JOIN val_sponsorcategory vsc ON vsc.sponsorCategoryID = s.sponsorCategoryID
				LEFT JOIN entityViewsCount e ON e.entityID 	= s.sponsorID	AND e.entitytypeID = 20				
				<!---LEFT JOIN contests cs ON cs.sponsorID = s.sponsorID--->
				
				WHERE 1 = 1
				
				<!--- ADD FILTERS TO QUERY  --->
				<cfif StructCount(arguments.filters) GT 0>
					
	  				<cfloop collection="#arguments.filters#" item="thisFilter">
					 
						<!--- SEARCH --->	
						<cfif  thisFilter EQ "keywords" AND TRIM(arguments.filters[thisFilter]) NEQ "">

							AND (  
									<!--- Search in sponsorName --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
										<cfif listFirst(arguments.filters[thisFilter]) NEQ thisKeyword>
											OR
										</cfif>
									 	s.sponsorName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
										
									</cfloop>

									<!--- Search over sponsorURL --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
										
										OR s.sponsorURL LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">

									</cfloop>
									<!--- Search over sponsorDEscription --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
										
										OR s.sponsorDescription LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">

									</cfloop>
								)
						<cfelseif	thisFilter EQ "sponsorCategoryID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND s.sponsorCategoryID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes">)
								
						<cfelseif thisFilter EQ "SearchCountryID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND sponsorCountryID = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">

						<cfelseif thisFilter EQ "tagName" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND s.sponsorID IN ( 
											SELECT entityID FROM tagging WHERE entityTypeID = 20 AND tagID IN ( 
												SELECT tagID FROM tags WHERE 1=1 
													<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
														OR tagName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
													</cfloop>
										 		)  
											)
						<cfelseif thisFilter EQ "SearchSponsorCategorySlug" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND vsc.sponsorCategorySlug = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">
	 					
	<!---					<cfelseif	thisFilter EQ "SearchTags" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND SponsorTags LIKE '%#arguments.filters[thisFilter]#%'--->
												 
	 					<!--- OTHER FLAGS --->
						<cfelseif	 arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
							AND s.#thisFilter# = #val(arguments.filters[thisFilter])# 
						</cfif>
					
					</cfloop>					
							
				</cfif>
				
				AND s.active = 1 
				GROUP BY s.sponsorID
				
				<cfif len(arguments.pagination.orderCol) GT 0>
					ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir#
				</cfif>
				
				LIMIT #arguments.pagination.offset#, #arguments.pagination.limit#
	          
			</cfquery>
			
			<cfquery datasource="#variables.datasource#" name="result.rows">
				SELECT FOUND_ROWS() AS total_count;
			</cfquery>			
			
			   
	 	    <cfcatch>

	 	    	<cfset result.message = errorMessage(messgae = 'database_query_error', error = variables.cfcatch)>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: getPublicSponsors", errorCatch = variables.cfcatch  )>	
			  	<cfreturn representationOf(result.message).withStatus(500) />

			 </cfcatch>
		
		</cftry>

	  	<cfset result.status  	= true />
		<cfset result.message = application.messages['sponsors_get_found_success'] />

	  	<cfset logAction( actionID = 1015, extra = "method: /Sponsors/GET" )>

		<cfreturn representationOf(result).withStatus(200) />

		
	</cffunction>

</cfcomponent>