<cfcomponent extends="taffyAPI.base" taffy_uri="/stats/" hint="Using this user can able to <code>GET</code> faq details">

	<cffunction name="GET" access="public" hint="Get Widget Stats" returntype="struct" output="false">
		<cfargument name="excludeWP" 	type="string" required="false"  default="false" hint="Exclude Wordpress from count"> 	
		<cfargument name="excludeBase"  type="string" required="false"  default="false" hint="Exclude Blog ID 0 from count"> 	
		<cfargument name="interval"  	type="string" required="false"  default="M" 	hint="D: Day - W: Week - M: Month - Y : YEAR - ALL">
		<cfargument name="action" 		type="string" required="false"  default=""		hint="null">
		<cfargument name="functionName" type="string" required="true"					hint="type of function">
		 
 		<!--- :: init result structure --->	
 		<cfset var result 	= "" />
		<cfset var local  	= StructNew() />
  	
		<!---<cftry>	--->

		<cfswitch expression="#arguments.functionName#">

			<cfcase value="getWidgetStats">
			
				<cfquery datasource="#variables.datasource#" name="local.query">
					SELECT
				
					  <!---(	SELECT  SUM(WidgetHitCount)
					  	FROM widgethitsdaily w
						<cfif arguments.excludeWP>
						INNER JOIN blogs b ON b.blogID = w.blogID AND b.blogURL NOT LIKE '%wordpress.com%'
						</cfif>
					  	WHERE  YEARWEEK(widgetHitDate) = YEARWEEK(CURRENT_TIMESTAMP) 
						<cfif arguments.excludeBase>AND w.BlogID > 0</cfif> ) AS W--->
					
					<!---  ,( SELECT  SUM(WidgetHitCount)
					  	 FROM widgethits w
						 <cfif arguments.excludeWP>
						 INNER JOIN blogs b ON b.blogID = w.blogID AND b.blogURL NOT LIKE '%wordpress.com%'
						 </cfif>	
					  	 WHERE  ( LEFT(widgetHitDate, 10) = CURDATE() ) 
					  	 <cfif arguments.excludeBase>AND w.BlogID > 0</cfif> ) AS D,--->
					
					  ( SELECT  SUM(WidgetHitCount)
					  	 FROM widgethitsdaily w
						 <cfif arguments.excludeWP>
						 INNER JOIN blogs b ON b.blogID = w.blogID AND b.blogURL NOT LIKE '%wordpress.com%'
						 </cfif>	
					  	 WHERE ( YEAR(widgetHitDate) = YEAR(CURDATE()) AND MONTH(widgetHitDate) = MONTH(CURDATE()) ) 
					  	 <cfif arguments.excludeBase>AND w.BlogID > 0</cfif> 	) M
					
					  ,( SELECT  SUM(WidgetHitCount)
					  	 FROM widgethitsdaily w
						 <cfif arguments.excludeWP>
						 INNER JOIN blogs b ON b.blogID = w.blogID AND b.blogURL NOT LIKE '%wordpress.com%'
						 </cfif>	
					  	 WHERE ( YEAR(widgetHitDate) = YEAR(CURDATE()) ) 
					  	 <cfif arguments.excludeBase>AND w.BlogID > 0</cfif> ) AS Y
						 
						 
					  ,( SELECT  SUM(WidgetHitCount)
							FROM widgethitsdaily w
							WHERE widgetHitDate >= DATE_SUB(CURDATE(), INTERVAL 8  DAY)
		          			AND widgetHitDate <= DATE_SUB(CURDATE(), INTERVAL 1  DAY)	
							<cfif arguments.excludeBase>AND w.BlogID > 0</cfif> 
						) AS A
						 
						,( SELECT SUM(WidgetHitCount)
						FROM widgethitsdaily w
						WHERE ( MONTH(widgetHitDate) = MONTH(DATE_SUB(CURDATE(), INTERVAL 1  MONTH)) ) ) AS LAST_M
						 
		   		</cfquery>
				
				<cfset local.widgetStats = StructNew()> 
				
				<!---<cfset local.widgetStats.d = local.query.d> --->
				<!---<cfset local.widgetStats.w = local.query.w> --->
				<cfset local.widgetStats.m = local.query.m> 
				<cfset local.widgetStats.y = local.query.y>  
				<cfset local.widgetStats.a = local.query.a>
				<cfset local.widgetStats.last_m = local.query.LAST_M>
				
				<cfquery datasource="#variables.datasource#" name="local.query" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
					SELECT count(b.blogID) as total
					FROM blogs b
					WHERE b.publisherStatusID IN (2,3) AND b.active = 1
				</cfquery>		
						
				<cfset local.widgetStats.total_publishers = local.query.total>  		  
				 
				<!--- // ADD Monthly AD Impressions Counter/Value ---> 
				
				<!--- // ADD Monthly Uniques Counter/Value ---> 
				 
				<cfset result = local.widgetStats /> 
		 	
		<!---	<cfcatch>
					<cfset result = 2000 /> 
					<cfset logAction( actionID = 666, extra = "method: /stats/GET/" errorCatch = variables.cfcatch )>	
					<cfreturn noData().withStatus(500)>
				</cfcatch>

			  	</cftry>--->
			
				<cfreturn representationOf(result).withStatus(200)/>

			</cfcase>

			<cfcase value="getWidgetHitsCount">

		 		<!--- :: init result structure --->	
		 		<cfset var result 	= "" />
				<cfset var local  	= StructNew() />
		  	
				<cftry> 	
					
					<cfquery datasource="#variables.datasource#" name="local.query" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
					    SELECT  SUM(WidgetHitCount) as totalHits, SUM(widgetHitUnique) AS uniqueHits
					    FROM widgethitsdaily w
						
						<cfif arguments.excludeWP>
						INNER JOIN blogs b ON b.blogID = w.blogID AND b.blogURL NOT LIKE '%wordpress.com%'
					    </cfif>
					    
					    WHERE 1 = 1
					    
					    <cfswitch expression="#arguments.interval#">
					    
						    <cfcase value="D">
						    AND ( LEFT(widgetHitDate, 10) = CURDATE() )
							</cfcase>

						    <cfcase value="W">
						    AND YEARWEEK(widgetHitDate) = YEARWEEK(CURRENT_TIMESTAMP)
							</cfcase>
							
						    <cfcase value="M">
						    AND ( YEAR(widgetHitDate) = YEAR(CURDATE()) AND MONTH(widgetHitDate) = MONTH(CURDATE()) )
							</cfcase>
							
						    <cfcase value="Y">
						    AND ( YEAR(widgetHitDate) = YEAR(CURDATE()) )
							</cfcase>
						
						</cfswitch>						 
			 			
						<cfif arguments.excludeBase>
					    AND w.BlogID > 0
					    </cfif>
			   
					</cfquery>
					 
					<cfset result = local.query /> 
			 	
					<cfcatch>
						
						<cfset logAction( actionID = 666, extra="method:/stats/GET", errorCatch = variables.cfcatch )>	
						<cfreturn noData().withStatus(500)>

					</cfcatch>

			  	</cftry>

				<!--- <cfset logAction( actionID = 666, extra="method:/stats/GET" errorCatch = variables.cfcatch )> --->
				<cfreturn representationOf(result).withStatus(200) />

			</cfcase>

			<cfcase value = "getRecent">
				
				<!--- :: init result structure --->	
				<cfset var result = StructNew() />
				<cfset var local  = StructNew() />
				<cfset result.status  	= false />
				<cfset result.message 	= "" />
		 
				 <cfscript>
					 // set filters
					local.attributes.filters 				= StructNew();
					local.attributes.pagination			= StructNew();
					local.attributes.pagination.Limit		= 1;
					local.attributes.pagination.offset		= 10;
					local.attributes.pagination.orderCol	= "blogDateVerified";
					local.attributes.pagination.orderDir	= "DESC";		 
					// invoke method in dataObj component 
					 
					local.tmp = httpRequest( methodName = 'GET', endPointOfURL = '/blogs/', timeout = 3000, parameters = local.attributes);
				</cfscript>	

				<cfif local.tmp.statuscode EQ '200 ok'>
					<cfset result.message = "success">
					<cfset result.status = true />
					<cfset local.recentBlogs = deserializeJson(local.tmp.filecontent)>
					<cfset result.recentBlogs = local.recentBlogs.dataset>
				<cfelse>
					<cfset result.recentBlogs = []>
				</cfif>
		 		
				<cfreturn representationOf(result).withStatus(200) />
			</cfcase>

		</cfswitch>

	</cffunction>	
		

</cfcomponent>