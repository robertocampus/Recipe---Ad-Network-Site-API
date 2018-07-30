<cfcomponent extends="taffyAPI.base" taffy:uri="/PublisherEarnings/" hint="Using this user can able to <code>Get</code> a single PublisherEarnings by passing blogID.">

	<cffunction name="GET" access="public" hint="Return publisher earnings queries" returntype="struct" output="true">
		<cfargument name="userID"  	  type="string"  required="true"  hint="user ID">
		<cfargument name="blogID"  	  type="string"  required="true"  hint="Blog ID">
		<cfargument name="month"  	  type="string"  required="true"  hint="Month (start date)">
		<cfargument name="auth_token" type="string"  required="true"  hint="Authentication Token" >
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset var local = StructNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>
		
		<cfscript>
			local.cd = DaysInMonth(arguments.month);
			local.start_date = arguments.month & "-01";
			local.end_date 	 = arguments.month & "-" & local.cd;
		</cfscript>
		<cftry>
			<cfquery datasource="#variables.datasource#" name="local.reconciledStatus">

				SELECT isReconciled
				FROM val_monthpayments
				WHERE month = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.month#">

			</cfquery>	
		
		 	<cfquery datasource="#variables.datasource#" name="local.getSiteID">

				SELECT DISTINCT meta_value AS site_id 
				FROM publishers_meta 
				WHERE meta_key = "site_id" 
				AND blogID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#">

			</cfquery>

		 	<cfset local.site_id = local.getSiteID.site_id>			
		 	
		 	<!--- // Reconciled? Then use pre-calculated data, otherwise use raw data table --->
		 	<cfif local.reconciledStatus.isReconciled EQ 1>
			 	
			 	<!--- RECONCILED --->
			 	<!-- record to getSiteDailyEarnings_US -->
				<cfquery datasource="#variables.datasource#" name="result.query">

					SELECT
					    period,
					    SUM(publisher_revenue) AS revenue,
					    SUM(Billable_Impressions_Delivered) AS impressions,
					    format(SUM(Billable_Impressions_Delivered),0) as impC,
					    CAST(SUM(publisher_revenue) AS DECIMAL(10,2)) AS earnings
					FROM report_revenue_daily
					WHERE 1 = 1
					AND site_id = '#local.site_id#'
					AND month = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.month#">
					AND isUS = 1
					GROUP BY period

				</cfquery>
				
				<cfquery datasource="#variables.datasource#" name="result.getSiteMontlyEarnings_US">	

					SELECT period, SUM(publisher_revenue) AS earnings, SUM(Billable_Impressions_Delivered) AS impressions
					FROM report_revenue_daily
					WHERE 1 = 1
					AND site_id = '#local.site_id#'
					AND month = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.month#">
					AND isUS = 1	

				</cfquery>
				
				<cfquery datasource="#variables.datasource#" name="result.getEarningsDetails_US">

					SELECT 
						CASE 
					        WHEN r.line_item_ID IS NULL THEN 'FBR Advertising Partners'
					        ELSE r.line_item_name
					    END AS line_item_name,
						r.eCPM AS order_eCPM,
					    Billable_Impressions_Delivered, 
					    r.publisher_revenue 
					FROM  report_revenue_bylineitem r
					WHERE site_id = '#local.site_id#'
					AND r.month = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.month#">
					AND r.isUS = 1
					ORDER BY r.line_item_name ASC	

				</cfquery>	
				
				<cfquery datasource="#variables.datasource#" name="result.getSiteDailyEarnings_nonUS">

					SELECT
					    period,
					    SUM(publisher_revenue) AS revenue,
					    SUM(Billable_Impressions_Delivered) AS impressions,
					    format(SUM(Billable_Impressions_Delivered),0) as impC,
					    CAST(SUM(publisher_revenue) AS DECIMAL(10,2)) AS earnings
					FROM report_revenue_daily
					WHERE 1 = 1
					AND site_id = '#local.site_id#'
					AND month = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.month#">
					AND isUS = 0
					GROUP BY period

				</cfquery>	
				
				<cfquery datasource="#variables.datasource#" name="result.getEarningsDetails_nonUS">

					SELECT 
						CASE 
					        WHEN r.line_item_ID IS NULL THEN 'FBR Advertising Partners'
					        ELSE r.line_item_name
					    END AS line_item_name,
						r.eCPM AS order_eCPM,
					    Billable_Impressions_Delivered, 
					    r.publisher_revenue 
					FROM  report_revenue_bylineitem r
					WHERE site_id = '#local.site_id#'
					AND r.month = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.month#">
					AND r.isUS = 0
					ORDER BY r.line_item_name ASC	

				</cfquery>
				
				<cfquery datasource="#variables.datasource#" name="result.getSiteMontlyEarnings_nonUS">	

					SELECT period, SUM(publisher_revenue) AS earnings, SUM(Billable_Impressions_Delivered) AS impressions
					FROM report_revenue_daily
					WHERE 1 = 1
					AND site_id = '#local.site_id#'
					AND month = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.month#">
					AND isUS = 0		

				</cfquery>
			
			<cfelse><!--- // Use non-reconciled full data --->
		  	 
		  	 	<!--- RAW DATA --->
		  	 <!-- record to getSiteDailyEarnings_US -->
			 	<cfquery datasource="#variables.datasource#" name="result.query">

					SELECT 
						right(period,5) AS period, 
						SUM(publisher_revenue) AS revenue,
						SUM(Billable_Impressions_Delivered) AS impressions,
						
						format(SUM(Billable_Impressions_Delivered),0) as impC,
						 
							CAST(SUM(publisher_revenue) AS DECIMAL(10,2)) AS earnings,
							CONCAT(CAST(SUM(Billable_Impressions_Delivered)/1000 AS DECIMAL(10,3)), ' K') AS imp
					
					FROM report_revenue_bypublisher
					WHERE 1 = 1
					AND site_id = '#local.site_id#'
					AND period >= '#local.start_date#' AND period <= '#local.end_date#'
					AND LCASE(country) = 'united states'
					
					GROUP BY period
					ORDER BY period ASC

				</cfquery>
				
				<cfquery datasource="#variables.datasource#" name="result.getSiteMontlyEarnings_US">

					SELECT period, SUM(publisher_revenue) AS earnings, SUM(Billable_Impressions_Delivered) AS impressions
					FROM report_revenue_bypublisher
					WHERE 1 = 1
					AND site_id = '#local.site_id#'
					AND period >= '#local.start_date#' AND period <= '#local.end_date#'
					AND LCASE(country) = 'united states'

				</cfquery>
			
				<cfquery datasource="#variables.datasource#" name="result.getEarningsDetails_US">

					SELECT  
						IF(vo.line_item_name IS NULL, ' Advertising Partners', vo.line_item_name) AS line_item_name,
						vo.order_eCPM,
						IF(vo.order_fillRate IS NULL, 0, vo.order_fillRate) AS order_fillRate,
							SUM(r.Billable_Impressions_Delivered) as Billable_Impressions_Delivered,
						SUM(r.publisher_revenue) as publisher_revenue
					
					FROM report_revenue_bypublisher r
					LEFT JOIN val_orders vo ON vo.line_item_id = r.line_item_id AND vo.month = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.month#">
					WHERE 1 = 1
					AND site_id = '#local.site_id#'
					AND period >= '#local.start_date#' AND period <= '#local.end_date#'
					AND LCASE(country) = 'united states'
						GROUP by r.line_item_ID
					ORDER BY r.line_item_name ASC

				</cfquery>
				
				<cfquery datasource="#variables.datasource#" name="result.getSiteDailyEarnings_nonUS">		

					SELECT 
						right(period,5) AS period,
						SUM(publisher_revenue) AS revenue,
						SUM(Billable_Impressions_Delivered) AS impressions,
						format(SUM(Billable_Impressions_Delivered),0) as impC,
						CAST(SUM(publisher_revenue) AS DECIMAL(10,2)) AS earnings,
						CONCAT(CAST(SUM(Billable_Impressions_Delivered)/1000 AS DECIMAL(10,3)), ' K') AS imp
					FROM report_revenue_bypublisher
					WHERE 1 = 1
					AND site_id = '#local.site_id#'
					AND period >= '#local.start_date#' AND period <= '#local.end_date#'
					AND LCASE(country) <> 'united states'
					GROUP BY period
					ORDER BY period ASC

				</cfquery>
					
				<cfquery datasource="#variables.datasource#" name="result.getEarningsDetails_nonUS">

					SELECT
						IF(vo.line_item_name IS NULL, ' Advertising Partners', vo.line_item_name) AS line_item_name,
						vo.order_eCPM_nonUS,
							SUM(r.Billable_Impressions_Delivered) as Billable_Impressions_Delivered,
						SUM(r.publisher_revenue) as publisher_revenue
					
					FROM report_revenue_bypublisher r
					LEFT JOIN val_orders vo ON vo.line_item_id = r.line_item_id AND vo.month = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.month#">
					WHERE 1 = 1
					AND site_id = '#local.site_id#'
					AND period >= '#local.start_date#' AND period <= '#local.end_date#'
					AND LCASE(country) <> 'united states'
					GROUP by r.line_item_ID
					ORDER BY SUM(r.publisher_revenue) DESC, r.line_item_name ASC

				</cfquery>		
				
				<cfquery datasource="#variables.datasource#" name="result.getSiteMontlyEarnings_nonUS">

					SELECT period, SUM(publisher_revenue) AS earnings, SUM(Billable_Impressions_Delivered) AS impressions
						FROM report_revenue_bypublisher
					WHERE 1 = 1
					AND site_id = '#local.site_id#'
					AND period >= '#local.start_date#' AND period <= '#local.end_date#'
					AND LCASE(country) <> 'united states'

				</cfquery>
			
			</cfif>
			<!--- // END: Reconciled ? --->

			   
				 
			<cfcatch>
				<!--- :: degrade gracefully :: --->
				
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>

				<!--- // 8700, error while get publisherEarnings record --->
				<cfset logAction( actionID = 666, userID = 1, errorCatch = variables.cfcatch  )>	
				<cfreturn representationOf(result.message).withStatus(500)>
	        </cfcatch>
			
		</cftry> 
	      		<!--- 8701:publisherEarnings record were got successflly --->
	    <!--- <cfset logAction( actionID = 8701, userID = 1, errorCatch = variables.cfcatch  )> --->
		<cfset result.status = true />
		<cfset result.message = application.messages['publisherEarnings_get_found_success']>
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>