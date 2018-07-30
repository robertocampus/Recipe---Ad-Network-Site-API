<cfcomponent extends="taffyAPI.base" taffy:uri="/entityViewsCount/" hint="Used to insert the view count.">
	
	<cffunction name="POST" access="public" hint="Used to insert the view count." output="false">
		<cfargument name="entityID" 		type="numeric" required="true" hint="Currently viewed entityID">
		<cfargument name="entityTypeID"  	type="numeric" required="true" hint="Currently viewed entityTypeID (ex: recipe,blog & etc..)">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />		

		<cftry>

		    <cfquery datasource="#variables.datasource#" name="local.entityViewsCount">
				
				SELECT * 
					FROM
						entityViewsCount
					Where 
						entityID 	  = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.entityID#" />
					AND 
						entityTypeID  = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.entityTypeID#" />

			</cfquery>

			<cfif local.entityViewsCount.recordCount >

				<cfset local.totalViewCount = local.entityViewsCount.count + 1 >
				
				<cfquery datasource="#variables.datasource#" name="local.query" result="entityCount"> 
					
					UPDATE entityViewsCount
						SET
							count = <cfqueryparam value="#local.totalViewCount#" cfsqltype="cf_sql_numeric" />,
							lastViewedDate = <cfqueryparam value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" cfsqltype="cf_sql_timestamp">
						WHERE
							viewsCountID  = <cfqueryparam cfsqltype="cf_sql_numeric" value="#local.entityViewsCount.viewsCountID#" />
						AND
							entityID 	  = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.entityID#" />
						AND 
							entityTypeID  = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.entityTypeID#" />

				</cfquery>

			<cfelse>

				<cfquery datasource="#variables.datasource#" name="local.query" result="entityCount">
					
					INSERT INTO entityViewsCount ( 										
										entityID,
										entityTypeID,
										count,
										lastViewedDate
									) VALUES (
										<cfqueryparam cfsqltype="cf_sql_numeric" 	value="#arguments.entityID#" />,
										<cfqueryparam cfsqltype="cf_sql_numeric" 	value="#arguments.entityTypeID#" />,
										<cfqueryparam cfsqltype="cf_sql_numeric" 	value="1" />,
										<cfqueryparam cfsqltype="cf_sql_timestamp"  value="#dateTimeFormat(now(), 'yyyy-mm-dd hh:nn:ss')#" >
									)						

				</cfquery>

			</cfif>
			
			
			<cfif entityCount.recordCount EQ 0 >

				<cfset result.message = application.messages['entityViewsCount_post_add_error']>
				<cfreturn noData().withStatus(404) />
				
			</cfif>
		   
		  	<cfcatch>				
				<!--- :: degrade gracefully :: --->
				<cfset local.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /entityViewsCount/ POST", errorCatch = variables.cfcatch  )>	
			  
			  	<cfreturn representationOf(local.message).withStatus(500) />

			</cfcatch>
		
	    </cftry>

	    <cfset result.status  	= true />
	    <cfset result.message = application.messages['entityViewsCount_post_add_success'] />
		
		<!--- 4002, Entity: Viewed, Entity was viewed, 1 --->
	  	<cfset local.tmp = logAction( actionID = 4002, extra = "method: /entityViewsCount/ POST"  )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>	

</cfcomponent>