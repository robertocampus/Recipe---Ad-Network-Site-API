<!--- POST method requires user authentication --->

<cfcomponent extends="taffyAPI.base" taffy:uri="/blogs/" hint="Using this user can able to <code>Get</code> all Blogs with their details by passing BlogID. Can also able to <code>Create</code> a new Blog.">
	
	<cffunction name="GET" access="public" hint="Return Blogs Listing DATA using filters and paging" output="false">
		<cfargument name="filters" 		type="struct" default="#StructNew()#" required="no" hint="Test Listing Filters struct">
		<cfargument name="pagination"   type="struct" default="#StructNew()#" required="no" hint="Test Listing Paging struct">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />
	  
		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);
		</cfscript>

		<cftry>

			<cfquery datasource="#variables.datasource#" name="result.query"><!---  cachedwithin="#CreateTimeSpan(0,1,0,0)#" --->
				DROP temporary table if exists _tmp_blog_search;
				CREATE temporary TABLE _tmp_blog_search  ( `blogID` INT(10) UNSIGNED NOT NULL,  PRIMARY KEY (`blogID`) ) ENGINE=MEMORY;				
				INSERT INTO _tmp_blog_search 
				SELECT 
					blogID
				FROM blogs b
				LEFT JOIN entityViewsCount e ON e.entityID 	=b.blogID	AND e.entitytypeID = 3
				WHERE  ( 1 = 1

					<!--- ADD FILTERS TO QUERY  --->
					<cfif StructCount(arguments.filters) GT 0>

						<cfloop collection="#arguments.filters#" item="thisFilter">
					 
							<!--- SIMPLE SEARCH on Test Name --->	
							<cfif 	thisFilter EQ "blogTitle" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogTitle LIKE '%#trim(arguments.filters[thisFilter])#%'
								
							<cfelseif	thisFilter EQ "blogURL" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogURL LIKE '%#trim(arguments.filters[thisFilter])#%'
								
							<cfelseif	thisFilter EQ "UserName" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( 
									SELECT blogID FROM userblogs WHERE userID IN (
										SELECT userID FROM users WHERE userFirstName LIKE '%#trim(arguments.filters[thisFilter])#%'	
																	OR userLastName  LIKE '%#trim(arguments.filters[thisFilter])#%'
										)
									)			
			                
							<cfelseif	thisFilter EQ "blogTags" AND TRIM(arguments.filters[thisFilter]) NEQ "">								
								AND blogID IN (	SELECT tg.entityID
													FROM tags AS t
													INNER JOIN tagging AS tg ON tg.tagID = t.tagID
													WHERE tg.entitytypeID = <cfqueryparam value="3" cfsqltype="cf_sql_integer"> 
													AND
													<cfloop list="#arguments.filters[thisFilter]#" index="tagName">									
														<cfif listFirst(arguments.filters[thisFilter]) NEQ tagName>
															OR
														</cfif>
													 	t.tagName LIKE '%#tagName#%'
													</cfloop>
												)
								
							<cfelseif	thisFilter EQ "keywords" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								
								AND ( 
									
									<!--- the first condition must not have an OR. All subsequent conditions must have an OR. --->
									
									<!--- Search in blogTitle --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
										
											<cfif listFirst(arguments.filters[thisFilter]) NEQ thisKeyword>
												OR
											</cfif>
												blogTitle LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">										

									</cfloop>

									
									<!--- Search over blogURL --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">									
																		
										OR blogURL LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">

									</cfloop>
									
									<!--- Search over tags - it needs to match tags in the tagging table - do a subquery as we are doing for the username --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">

										OR blogID IN ( SELECT tg.entityID FROM  tags t 
													INNER JOIN tagging tg ON tg.tagID = t.tagID AND tg.entityTypeID = 3 
													WHERE t.tagName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
												)

									</cfloop>
									
									<!--- Search over country - left join with val_country - do a subquery as we are doing for the username --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">	

										OR countryID IN (SELECT countryID FROM val_countries vc WHERE vc.countryFullName LIKE '%#thisKeyword#%')

									</cfloop>

									<cfloop list=#"arguments.filters[thisFilter]"# index="thisKeyword">
										OR languageID IN (SELECT languageID FROM val_language vl WHERE vl.languagename LIKE '%#thisKeyword#%')
									</cfloop>
								)								
			                    					
							<cfelseif	thisFilter EQ "statusID" AND TRIM(arguments.filters[thisFilter]) NEQ 0>
								AND statusID IN ( #arguments.filters[thisFilter]# )

							<cfelseif	thisFilter EQ "publisherStatusID" AND TRIM(arguments.filters[thisFilter]) NEQ 0>
								AND publisherStatusID IN ( #arguments.filters[thisFilter]# )
			                    		
							<cfelseif	thisFilter EQ "blogID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#" list="yes"> )
						
							<cfelseif	thisFilter EQ "greaterThanBlogID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND BlogID > #arguments.filters[thisFilter]#
								
							<cfelseif	thisFilter EQ "blogDateCreated" AND isDate(arguments.filters[thisFilter])>
								AND left(blogDateCreated,10) = '#DateFormat(arguments.filters[thisFilter], "YYYY-MM-DD")#'	
								
							<cfelseif	thisFilter EQ "blogDateApproved" AND isDate(arguments.filters[thisFilter])>
								AND left(blogDateApproved,10) = '#DateFormat(arguments.filters[thisFilter], "YYYY-MM-DD")#'											
							<cfelseif	thisFilter EQ "blogDateVerified" AND isDate(arguments.filters[thisFilter])>
								AND left(blogDateVerified,10) = '#DateFormat(arguments.filters[thisFilter], "YYYY-MM-DD")#'	
			                    
							<cfelseif	thisFilter EQ "excludeWidgetVerified" AND TRIM(arguments.filters[thisFilter]) EQ 1>
								AND BlogID NOT IN ( SELECT DISTINCT blogID FROM widgethits )
			                    AND BlogID NOT IN ( SELECT DISTINCT blogID FROM widgethitsdaily )
			                    
							<cfelseif	thisFilter EQ "excludeWordpress" AND TRIM(arguments.filters[thisFilter]) EQ 1>
								AND blogURL NOT LIKE '%wordpress.com%' 
			                                                                    
							<cfelseif	thisFilter EQ "active" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND active IN ( #arguments.filters[thisFilter]# )
			                    						
							<cfelseif	thisFilter EQ "userEmail" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT blogID FROM userblogs WHERE userID IN ( SELECT userID FROM users WHERE userEmail LIKE '%#arguments.filters[thisFilter]#%' ) )

							<cfelseif	thisFilter EQ "greaterThanBlogID" AND TRIM(arguments.filters[thisFilter]) NEQ 0>
								AND blogID >( #arguments.filters[thisFilter]# )					
						
							<cfelseif	thisFilter EQ "hitsWeekly" AND isNumeric(arguments.filters[thisFilter])>
								
								<cfif arguments.filters[thisFilter] EQ 0>
									AND ( hitsWeekly = 0 OR hitsWeekly IS NULL )
								<cfelse>
									AND hitsWeekly >= ( #arguments.filters[thisFilter]# )
								</cfif>	
													
							<cfelseif	thisFilter EQ "widgetHitDate" AND TRIM(arguments.filters[thisFilter]) NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								
								<cfif arguments.filters[thisFilter] GT 0>
									AND blogID IN ( SELECT DISTINCT blogID FROM widgethitsdaily WHERE widgetHitDate >= DATE_SUB(curdate(), INTERVAL #arguments.filters[thisFilter]# DAY ) )
								<cfelse>
									AND blogID NOT IN ( SELECT DISTINCT BlogID FROM widgethitsdaily WHERE widgetHitDate >= DATE_SUB(curdate(), INTERVAL #ABS(arguments.filters[thisFilter])# DAY ) )
								</cfif>	

							<cfelseif	thisFilter EQ "blogDateApproved" AND TRIM(arguments.filters[thisFilter]) NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								
								<cfif arguments.filters[thisFilter] GT 0>
									AND blogDateApproved >= DATE_SUB(curdate(), INTERVAL #abs(arguments.filters[thisFilter])# DAY )	
								<cfelse>
									AND blogDateApproved <= DATE_SUB(curdate(), INTERVAL #abs(arguments.filters[thisFilter])# DAY )
								</cfif>	

							<cfelseif	thisFilter EQ "blogDateVerified" AND TRIM(arguments.filters[thisFilter]) NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								
								<cfif arguments.filters[thisFilter] GT 0>
									AND blogDateVerified >= DATE_SUB(curdate(), INTERVAL #abs(arguments.filters[thisFilter])# DAY )	
								<cfelse>
									AND blogDateVerified <= DATE_SUB(curdate(), INTERVAL #abs(arguments.filters[thisFilter])# DAY )
								</cfif>	
						
							<cfelseif	thisFilter EQ "userID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT BlogID FROM userblogs WHERE userID = #arguments.filters[thisFilter]# )    
								
							<cfelseif	thisFilter EQ "countryID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND countryID = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	

							<cfelseif	thisFilter EQ "languageID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND languageID = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">						
								
							<!--- Publisher Checks --->
							<cfelseif	thisFilter EQ "blogIsPublisher" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogIsPublisher  = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">

							<cfelseif	thisFilter EQ "publisherStatusID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND publisherStatusID IN ( #arguments.filters[thisFilter]# ) 

							<!--- STATUSCHECK --->
							<cfelseif	thisFilter EQ "isWidget" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isWidget = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)

							<cfelseif	thisFilter EQ "isFoodBuzzPublisher" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isFoodBuzzPublisher = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
								                 
							<cfelseif	thisFilter EQ "isWordpress" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isWordpress = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
									 
							<cfelseif	thisFilter EQ "isError" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isError = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
								 
							<cfelseif	thisFilter EQ "isBlogSpot" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isBlogSpot = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
									 			
							<cfelseif	thisFilter EQ "isTypepad" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isTypepad = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)

							<cfelseif	thisFilter EQ "isFrameset" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isFrameset = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
												
							<cfelseif	thisFilter EQ "cfhttpStatusCode" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE cfhttpStatusCode = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
											
							<!--- WINNERS --->					
							<cfelseif	thisFilter EQ "BlogWinners" AND TRIM(arguments.filters[thisFilter]) EQ 1>
								AND blogID IN ( SELECT DISTINCT c.blogID FROM contestwinners c  )
				
							<cfelseif	thisFilter EQ "BlogWinners" AND TRIM(arguments.filters[thisFilter]) EQ 2>
								AND blogID NOT IN ( SELECT DISTINCT c.blogID FROM contestwinners c  )

							<cfelseif	thisFilter EQ "blogThumbnailStatus" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogThumbnailStatus = <cfqueryparam value="#arguments.filters[thisFilter]#" cfsqltype="cf_sql_varchar">	

							<cfelseif	thisFilter EQ "active" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND active = <cfqueryparam value="#arguments.filters[thisFilter]#" cfsqltype="cf_sql_integer">					
																			 
							<!--- OTHER FLAGS --->
							<cfelseif	 arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								AND #thisFilter# = #val(arguments.filters[thisFilter])#
							</cfif>
							
						</cfloop>					
							
					</cfif>						
				)				
				AND isFlagged = <cfqueryparam value="0" cfsqltype="cf_sql_integer">				
				GROUP BY blogID
				<cfif len(arguments.pagination.orderCol) GT 0>ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir#</cfif>;				
				
			    SELECT  
			    		b.blogID,
			    		b.blogTitle,
			    		b.blogURL,
			    		b.blogSlug,
			    		b.blogDescription,
			    		(SELECT GROUP_CONCAT( t.tagName )
						FROM tags AS t
						INNER JOIN tagging AS tg ON tg.tagID = t.tagID
						WHERE tg.entityID = b.blogID
						AND tg.entitytypeID = <cfqueryparam value="3" cfsqltype="cf_sql_integer"> ) AS 'blogTags',
			    		b.publisherStatusID,
			    		b.isBeacon,
			    		b.isTal,
			    		b.statusID,
			    		b.publisherDateApproved,
			    		b.privacyPolicyURL,
			    		b.blogRSS,
						VS.statusName,
						U.userID,
						U.userName AS authorUserName,
						U.userFirstName AS authorFirstName,
						U.userLastName AS authorLastName,
						b.blogDateCreated,
						b.blogDateVerified,
						b.hits AS widgetHitCount,
						b.active,
						vc.countryName,
						vl.languagename,
						b.facebookPageURL,
						CONCAT( i.imagePath, '/', i.imageName ) AS 'blog_FullSize_Image',
						CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'blog_Thumb_Image',
						CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'blog_mini_Image',
						e.count AS 'popularity'
						,(SELECT count(userID) FROM users_follow WHERE entityID = b.blogID AND entitytypeID = 3 AND followStatus = 1 ) AS 'blog_totalFollowers'						

					FROM blogs b
					INNER JOIN ( SELECT blogID FROM _tmp_blog_search LIMIT #arguments.pagination.offset#, #arguments.pagination.limit# ) t ON t.blogID = b.blogID
					INNER JOIN val_status VS ON VS.statusID = b.statusID
					LEFT JOIN userblogs UB ON UB.blogID   = b.blogID
					LEFT JOIN users U  ON U.userID    = UB.userID
					LEFT JOIN val_countries vc ON vc.countryID = b.countryID
					LEFT JOIN val_language vl ON vl.languageID = b.languageID
					LEFT JOIN images i on i.entityID = b.blogID AND i.entityTypeID = 3
					LEFT JOIN entityViewsCount e ON e.entityID 	=b.blogID	AND e.entitytypeID = 3
					
					WHERE 1 = 1 

				GROUP BY b.blogID
				<cfif len(arguments.pagination.orderCol) GT 0>ORDER BY <cfif #arguments.pagination.orderCol# EQ 'count'>popularity<cfelse>#arguments.pagination.orderCol#</cfif> #arguments.pagination.orderDir#</cfif>;			

			</cfquery>

			<cfquery datasource="#variables.dataSource#" name="local.rows">
				SELECT 
					blogID
				FROM blogs b
				LEFT JOIN entityViewsCount e ON e.entityID 	=b.blogID	AND e.entitytypeID = 3
				WHERE  ( 1 = 1

					<!--- ADD FILTERS TO QUERY  --->
					<cfif StructCount(arguments.filters) GT 0>

						<cfloop collection="#arguments.filters#" item="thisFilter">
					 
							<!--- SIMPLE SEARCH on Test Name --->	
							<cfif 	thisFilter EQ "blogTitle" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogTitle LIKE '%#trim(arguments.filters[thisFilter])#%'
								
							<cfelseif	thisFilter EQ "blogURL" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogURL LIKE '%#trim(arguments.filters[thisFilter])#%'
								
							<cfelseif	thisFilter EQ "UserName" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( 
									SELECT blogID FROM userblogs WHERE userID IN (
										SELECT userID FROM users WHERE userFirstName LIKE '%#trim(arguments.filters[thisFilter])#%'	
																	OR userLastName  LIKE '%#trim(arguments.filters[thisFilter])#%'
										)
									)			
			                
							<cfelseif	thisFilter EQ "blogTags" AND TRIM(arguments.filters[thisFilter]) NEQ "">								
								AND blogID IN (	SELECT tg.entityID
													FROM tags AS t
													INNER JOIN tagging AS tg ON tg.tagID = t.tagID
													WHERE tg.entitytypeID = <cfqueryparam value="3" cfsqltype="cf_sql_integer"> 
													AND
													<cfloop list="#arguments.filters[thisFilter]#" index="tagName">									
														<cfif listFirst(arguments.filters[thisFilter]) NEQ tagName>
															OR
														</cfif>
													 	t.tagName LIKE '%#tagName#%'
													</cfloop>
												)
								
							<cfelseif	thisFilter EQ "keywords" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								
								AND ( 
									
									<!--- the first condition must not have an OR. All subsequent conditions must have an OR. --->
									
									<!--- Search in blogTitle --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">
										
											<cfif listFirst(arguments.filters[thisFilter]) NEQ thisKeyword>
												OR
											</cfif>
												blogTitle LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">										

									</cfloop>

									
									<!--- Search over blogURL --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">									
																		
										OR blogURL LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">

									</cfloop>
									
									<!--- Search over tags - it needs to match tags in the tagging table - do a subquery as we are doing for the username --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">

										OR blogID IN ( SELECT tg.entityID FROM  tags t 
													INNER JOIN tagging tg ON tg.tagID = t.tagID AND tg.entityTypeID = 3 
													WHERE t.tagName LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#thisKeyword#%">
												)

									</cfloop>
									
									<!--- Search over country - left join with val_country - do a subquery as we are doing for the username --->
									<cfloop list="#arguments.filters[thisFilter]#" index="thisKeyword">	

										OR countryID IN (SELECT countryID FROM val_countries vc WHERE vc.countryFullName LIKE '%#thisKeyword#%')

									</cfloop>

									<cfloop list=#"arguments.filters[thisFilter]"# index="thisKeyword">
										OR languageID IN (SELECT languageID FROM val_language vl WHERE vl.languagename LIKE '%#thisKeyword#%')
									</cfloop>
								)								
			                    					
							<cfelseif	thisFilter EQ "statusID" AND TRIM(arguments.filters[thisFilter]) NEQ 0>
								AND statusID IN ( #arguments.filters[thisFilter]# )

							<cfelseif	thisFilter EQ "publisherStatusID" AND TRIM(arguments.filters[thisFilter]) NEQ 0>
								AND publisherStatusID IN ( #arguments.filters[thisFilter]# )
			                    		
							<cfelseif	thisFilter EQ "blogID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#" list="yes"> )
						
							<cfelseif	thisFilter EQ "greaterThanBlogID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND BlogID > #arguments.filters[thisFilter]#
								
							<cfelseif	thisFilter EQ "blogDateCreated" AND isDate(arguments.filters[thisFilter])>
								AND left(blogDateCreated,10) = '#DateFormat(arguments.filters[thisFilter], "YYYY-MM-DD")#'	
								
							<cfelseif	thisFilter EQ "blogDateApproved" AND isDate(arguments.filters[thisFilter])>
								AND left(blogDateApproved,10) = '#DateFormat(arguments.filters[thisFilter], "YYYY-MM-DD")#'											
							<cfelseif	thisFilter EQ "blogDateVerified" AND isDate(arguments.filters[thisFilter])>
								AND left(blogDateVerified,10) = '#DateFormat(arguments.filters[thisFilter], "YYYY-MM-DD")#'	
			                    
							<cfelseif	thisFilter EQ "excludeWidgetVerified" AND TRIM(arguments.filters[thisFilter]) EQ 1>
								AND BlogID NOT IN ( SELECT DISTINCT blogID FROM widgethits )
			                    AND BlogID NOT IN ( SELECT DISTINCT blogID FROM widgethitsdaily )
			                    
							<cfelseif	thisFilter EQ "excludeWordpress" AND TRIM(arguments.filters[thisFilter]) EQ 1>
								AND blogURL NOT LIKE '%wordpress.com%' 
			                                                                    
							<cfelseif	thisFilter EQ "active" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND active IN ( #arguments.filters[thisFilter]# )
			                    						
							<cfelseif	thisFilter EQ "userEmail" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT blogID FROM userblogs WHERE userID IN ( SELECT userID FROM users WHERE userEmail LIKE '%#arguments.filters[thisFilter]#%' ) )

							<cfelseif	thisFilter EQ "greaterThanBlogID" AND TRIM(arguments.filters[thisFilter]) NEQ 0>
								AND blogID >( #arguments.filters[thisFilter]# )					
						
							<cfelseif	thisFilter EQ "hitsWeekly" AND isNumeric(arguments.filters[thisFilter])>
								
								<cfif arguments.filters[thisFilter] EQ 0>
									AND ( hitsWeekly = 0 OR hitsWeekly IS NULL )
								<cfelse>
									AND hitsWeekly >= ( #arguments.filters[thisFilter]# )
								</cfif>	
													
							<cfelseif	thisFilter EQ "widgetHitDate" AND TRIM(arguments.filters[thisFilter]) NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								
								<cfif arguments.filters[thisFilter] GT 0>
									AND blogID IN ( SELECT DISTINCT blogID FROM widgethitsdaily WHERE widgetHitDate >= DATE_SUB(curdate(), INTERVAL #arguments.filters[thisFilter]# DAY ) )
								<cfelse>
									AND blogID NOT IN ( SELECT DISTINCT BlogID FROM widgethitsdaily WHERE widgetHitDate >= DATE_SUB(curdate(), INTERVAL #ABS(arguments.filters[thisFilter])# DAY ) )
								</cfif>	

							<cfelseif	thisFilter EQ "blogDateApproved" AND TRIM(arguments.filters[thisFilter]) NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								
								<cfif arguments.filters[thisFilter] GT 0>
									AND blogDateApproved >= DATE_SUB(curdate(), INTERVAL #abs(arguments.filters[thisFilter])# DAY )	
								<cfelse>
									AND blogDateApproved <= DATE_SUB(curdate(), INTERVAL #abs(arguments.filters[thisFilter])# DAY )
								</cfif>	

							<cfelseif	thisFilter EQ "blogDateVerified" AND TRIM(arguments.filters[thisFilter]) NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								
								<cfif arguments.filters[thisFilter] GT 0>
									AND blogDateVerified >= DATE_SUB(curdate(), INTERVAL #abs(arguments.filters[thisFilter])# DAY )	
								<cfelse>
									AND blogDateVerified <= DATE_SUB(curdate(), INTERVAL #abs(arguments.filters[thisFilter])# DAY )
								</cfif>	
						
							<cfelseif	thisFilter EQ "userID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT BlogID FROM userblogs WHERE userID = #arguments.filters[thisFilter]# )    
								
							<cfelseif	thisFilter EQ "countryID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND countryID = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	

							<cfelseif	thisFilter EQ "languageID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND languageID = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">						
								
							<!--- Publisher Checks --->
							<cfelseif	thisFilter EQ "blogIsPublisher" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogIsPublisher  = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">

							<cfelseif	thisFilter EQ "publisherStatusID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND publisherStatusID IN ( #arguments.filters[thisFilter]# ) 

							<!--- STATUSCHECK --->
							<cfelseif	thisFilter EQ "isWidget" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isWidget = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)

							<cfelseif	thisFilter EQ "isFoodBuzzPublisher" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isFoodBuzzPublisher = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
								                 
							<cfelseif	thisFilter EQ "isWordpress" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isWordpress = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
									 
							<cfelseif	thisFilter EQ "isError" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isError = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
								 
							<cfelseif	thisFilter EQ "isBlogSpot" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isBlogSpot = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
									 			
							<cfelseif	thisFilter EQ "isTypepad" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isTypepad = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)

							<cfelseif	thisFilter EQ "isFrameset" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE isFrameset = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
												
							<cfelseif	thisFilter EQ "cfhttpStatusCode" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogID IN ( SELECT DISTINCT blogID FROM statuscheck WHERE cfhttpStatusCode = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	)
											
							<!--- WINNERS --->					
							<cfelseif	thisFilter EQ "BlogWinners" AND TRIM(arguments.filters[thisFilter]) EQ 1>
								AND blogID IN ( SELECT DISTINCT c.blogID FROM contestwinners c  )
				
							<cfelseif	thisFilter EQ "BlogWinners" AND TRIM(arguments.filters[thisFilter]) EQ 2>
								AND blogID NOT IN ( SELECT DISTINCT c.blogID FROM contestwinners c  )

							<cfelseif	thisFilter EQ "blogThumbnailStatus" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND blogThumbnailStatus = <cfqueryparam value="#arguments.filters[thisFilter]#" cfsqltype="cf_sql_varchar">	

							<cfelseif	thisFilter EQ "active" AND TRIM(arguments.filters[thisFilter]) NEQ "">
								AND active = <cfqueryparam value="#arguments.filters[thisFilter]#" cfsqltype="cf_sql_integer">					
																			 
							<!--- OTHER FLAGS --->
							<cfelseif	 arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
								AND #thisFilter# = #val(arguments.filters[thisFilter])#
							</cfif>
							
						</cfloop>					
							
					</cfif>						
				)				
				AND isFlagged = <cfqueryparam value="0" cfsqltype="cf_sql_integer">				
				GROUP BY blogID;
			</cfquery>

			<cfset result.rows.total_count = local.rows.recordCount >

			<cfif result.rows.total_count EQ 0 >

				<cfset result.message = application.messages['blogs_get_found_error']>
				<cfreturn representationOf(result).withStatus(200) />
				
			</cfif>

			<cfcatch>

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /blogs/GET", errorCatch = variables.cfcatch  )>
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
		</cftry>
		
		<cfset result.status  	= true />
		
		<cfset result.message = application.messages['blogs_get_found_success']>

	  	<cfset logAction( actionID = 201, extra = "method: /blogs/GET"  )>

		<cfreturn representationOf(result).withStatus(200) />
		
	</cffunction>

	<cffunction name="POST" access="public" returntype="Struct" hint="Create a new blog" auth="true" >
		<cfargument name="blogTitle" 		type="string" 	required="yes">		
		<cfargument name="blogURL" 			type="string" 	required="no" default="" >
		<cfargument name="blogRSS" 			type="string" 	required="no" default="" >
		<cfargument name="blogTags"			type="string" 	required="no" default="" >
		<cfargument name="blogDescription" 	type="string" 	required="no" default="" >
		<cfargument name="privacyPolicyURL"	type="string" 	required="no" default="" >
		<cfargument name="facebookPageURL"	type="string" 	required="no" default="" >
		<cfargument name="facebookPageID"	type="numeric" 	required="no" default="0" >
		<cfargument name="languageID" 		type="string" 	required="no" default="" >
		<cfargument name="active" 			type="numeric" 	required="no" default="1" >
		<cfargument name="userID" 			type="numeric" 	required="yes" hint="userID">
		<cfargument name="imageID" 			type="numeric" 	required="no" default="0" >
		<cfargument name="auth_token" 		type="string" 	required="yes" hint="User authorization token (auth_token)">
		
		<cftry>			

			<!--- START:: Inserting Blog details into the blogs table--->
			<cfset arguments.blogSlug = toSlug(arguments.blogTitle)>
			<cfset local.user =  httpRequest( methodName = "GET", endPointOfURL = "/user/#arguments.userID#", timeout = 3000)>

			<cfset local.userdetails = deserializeJson(local.user.filecontent).dataset>
			<cfset local.userCountryID = local.userdetails[1].userCountryID>

			<cfquery datasource="#variables.dataSource#" name="result.query" result="qry">
				INSERT INTO blogs (
									blogTitle,
									blogSlug,
									blogURL,
									blogRSS,
									blogDescription,
									languageID,
									blogDateCreated,
									countryID,
									privacyPolicyURL,
									facebookPageURL,
									facebookPageID,								
									active
								)
					VALUES( 
							<cfqueryparam value="#arguments.blogTitle#" 		cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.blogSlug#" 			cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.blogURL#" 			cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.blogRSS#" 			cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.blogDescription#" 	cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.languageID#" 		cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">,
							<cfqueryparam value="#local.userCountryID#"    		cfsqltype="cf_sql_numeric">,
							<cfqueryparam value="#arguments.privacyPolicyURL#" 	cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.facebookPageURL#" 	cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#arguments.facebookPageID#" 	cfsqltype="cf_sql_numeric">,
							<cfqueryparam value="#arguments.active#" 			cfsqltype="cf_sql_numeric">
						)
			</cfquery>
			<!--- END:: Inserting Blog details into the blogs table--->

			<cfset local.blogID = qry.GENERATED_KEY >
			<!--- START:: Inserting USER Blog details into the userblogs table--->
			<cfquery datasource="#variables.dataSource#" name="result.query" result="qry">
				INSERT INTO userblogs (
									userID,
									blogID
								)
					VALUES( 
							<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_numeric">,
							<cfqueryparam value="#local.blogID#" cfsqltype="cf_sql_numeric">
						)
			</cfquery>
			<!--- END:: Inserting USER Blog details into the userblogs table--->

			<!--- START :: INSERT blog tags in tagging table --->
			<cfif structKeyExists(arguments,'blogTags') AND arguments.blogTags NEQ ''>
				
				<cfset local.attributes = structNew()>
				<cfset local.attributes.entityID 			= local.blogID>
				<cfset local.attributes.entityTypeID        = 3>
				<cfset local.attributes.userID 				= arguments.userID>
				<cfset local.attributes.auth_token 			= arguments.auth_token>
				<cfset local.attributes.tags 				= arguments.blogTags>

				<cfset blogtags = httpRequest( methodName = 'POST', endPointOfURL = '/tags', timeout = 3000, parameters = local.attributes)>

			</cfif>
			<!--- END :: INSERT blog tags in tagging table --->

			<!--- START:: checking does the blog image is exists or not?--->
			<cfif structKeyExists(arguments, "imageID") AND arguments.imageID NEQ 0 >

				<cfset structClear(local.attributes)>

				<cfset local.attributes.entityID 	   = local.blogID />				
				<cfset local.attributes.entityTypeName = 'blog' />

				<cfset local.imageResponse = httpRequest( methodName = 'PUT', endPointOfURL = '/image/#arguments.imageID#', timeout = 3000, parameters = local.attributes ) />

				<cfset local.responseData = deserializeJSON(local.imageResponse.fileContent) >
				
			</cfif>
			<!--- END:: checking does the blog image is exists or not?--->

			<!--- START:: Getting the inserted blog details--->
			<cfquery datasource="#variables.dataSource#" name="result.query">
				SELECT 	blogID,
						blogTitle,
						blogSlug,
						blogURL,
						blogRSS,
						blogDescription
						,(SELECT GROUP_CONCAT( t.tagName )
						FROM tags AS t
						INNER JOIN tagging AS tg ON tg.tagID = t.tagID
						WHERE tg.entityID = <cfqueryparam value="#local.blogID#" cfsqltype="cf_sql_integer" >
						AND tg.entitytypeID = <cfqueryparam value="3" cfsqltype="cf_sql_integer"> ) AS 'blogTags',
						blogDateCreated,
						active
					FROM blogs 
						WHERE blogID = <cfqueryparam value="#local.blogID#" cfsqltype="cf_sql_numeric">
			</cfquery>
			<!--- END:: Getting the inserted blog details--->

			<cfcatch>	

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /blogs/POST", errorCatch = variables.cfcatch  )>
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
	    </cftry>

	    <cfset result.status  	= true />
		<cfset result.message = application.messages['blogs_post_addblog_success']>

	  	<cfset logAction( actionID = 301, extra = "method: /blogs/POST"  )>

		<cfreturn representationOf(result).withStatus(200)>

	</cffunction>

</cfcomponent>