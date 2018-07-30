<cfcomponent extends="taffyAPI.base" taffy_uri="/faq/" hint="Using this user can able to <code>GET</code> faq details">

	<cffunction name="GET" access="public" hint="Retrieve FAQ question/answers records and passes them as query in struct" returntype="struct">
		<cfargument name="questionTypeID" 	type="string" default="" 	required="false" hint="Question Type ID">
		<cfargument name="searchText" 		type="string"  default="" 	required="false" hint="Search">
 
		<!--- // init result structure --->	
		<cfset var result = StructNew() />
		<cfset var local  = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />
 
		<cftry>
		
	 		<cfquery datasource="#variables.datasource#" name="result.query" >

				SELECT q.questionID, q.questionText, q.questionAnswer, q.questionTypeID, VQ.questionTypeName, VQ.questionTypeDescription
				FROM questions q
				LEFT JOIN val_questiontype VQ on VQ.questionTypeID = q.questionTypeID
				
				WHERE q.active = 1
				
				<!--- SEARCH --->
				<cfif arguments.searchText NEQ "">
					AND q.questionText LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#arguments.searchText#%">
				</cfif>
				
				<cfif isNumeric(arguments.questionTypeID) AND arguments.questionTypeID NEQ "">
					AND q.questionTypeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.questionTypeID#">
				</cfif>
			
				ORDER BY VQ.questionTypeName ASC, q.questionText ASC

			</cfquery>

			<cfif NOT result.query.recordCount>
				
				<cfset result.message = application.messages['faq_get_found_error']>
				<cfreturn representationOf(result).withStatus(404)>
			</cfif>

			<cfcatch>
				
			  	<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
			  	<cfset logAction( actionID = 661, extra = "method:/faq/GET", errorCatch = variables.cfcatch  )>
			  	<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>	
	 		  	<cfset representationOf(result.message).withStatus(500)>

			</cfcatch>
				
		</cftry>

		<cfset result.status = true />	
		<cfset result.message = application.messages['faq_get_found_success']>
		
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>