<cfcomponent extends="taffyAPI.base" taffy:uri="/publisherPayments/" hint="used to get publisher Payment Records">

	<cffunction name="GET" access="public" hint="Return publisher payment history QUERY" returntype="struct" output="true" auth="true">
		<cfargument name="userID"  	type="string"  	required="true"  hint="User ID">
		<cfargument name="auth_token" type="string" required="true"  hint="auth_token of the user">
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset var local = StructNew() />
		<cfset result['status'] = false />
		<cfset result['message'] = ''>

		<cftry>
			
			<cfquery datasource="#variables.datasource#" name="result.query">
				SELECT 
						id,
						userID,
						blogID,
						publisher_ID,
						site_ID,
						currency,
						billable_impressions_delivered,
						amount,
						period,
						dateIssued,
						paymentEmail,
						isCompleted,
						paypal_transactionID,
						paypal_status,
						paypal_reason_code,
						paypal_fee,
						paypal_mass_transaction_id,
						paypal_custom_note
					
				FROM report_publisher_payment_history
				
				WHERE 1 = 1 
				AND userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				ORDER BY period DESC
			</cfquery>		
		
		   
			 
			<cfcatch>

			    <!--- :: degrade gracefully :: --->
			    <cfset result.message = errorMessage(message = 'publisherpayment_get_found_error', error = variables.cfcatch)>
			       
			    <!--- // 8601, Error while getting payment record --->
				<cfset logAction( actionID = 8601, userID = 1, errorCatch = variables.cfcatch  )>	
			  	<cfreturn representationOf(result.message).withStatus(500)>

	        </cfcatch>
			
	    </cftry> 
		
	      <!--- 8602:success:payment record were got successfully. --->

	    <cfset logAction( actionID = 8602, userID = arguments.userID, extra = "method: /publisherPayments/GET")>	
	    <cfset result.status = true>
	    <cfset result.message = application.messages['publisherpayment_get_found_success']>
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>