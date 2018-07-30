<cfcomponent extends="taffyAPI.base" taffy:uri="/tagClouds/" hint="Using this user can get tags cloud Listing DATA">

	<cffunction name="GET" access="public" hint="Return tags cloud Listing DATA using filters and pagination" returntype="struct" output="true">
		<cfargument name="filters" 		type="struct"  required="false" default="#StructNew()#"  hint="Blog Listing Filters struct">
		<cfargument name="pagination"  	type="struct"  required="false" default="#StructNew()#"  hint="Blog Listing Pagination struct">		
		<cfargument name="entityTypeID"	type="numeric" required="true">
 		
 		<!--- :: init result structure --->	
		<cfset result 	 = StructNew() />
		<cfset local 	 = StructNew() />
		<cfset result.status = false />
    
   		<cfparam name="arguments.pagination.orderCol" default="total">
   		<cfparam name="arguments.pagination.orderDir" default="DESC">

		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);

		</cfscript>

		<cftry>

			<cfquery datasource="#variables.datasource#" name="local.query">

				SELECT 
						t.tagID,
						t.tagName,
						COUNT(tg.tagID) AS total
					FROM tagging tg
					INNER JOIN tags t ON t.tagID = tg.tagID
				WHERE  1 = 1					
					<cfif arguments.entityTypeID NEQ 0 >
						AND  tg.entityTypeID = <cfqueryparam value="#arguments.entityTypeID#" cfsqltype="cf_sql_integer">
					</cfif>
				GROUP BY tg.tagID 
				ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir# LIMIT #arguments.pagination.offset#, #arguments.pagination.limit# 
				
			</cfquery>
			
			
			<cfset local.tt=queryNew("tagName,total,percentage,frequent", "varchar,varchar,varchar,varchar")>
			<!--- // START: Any records? --->
			<cfif local.query.recordCount GT 0>

				<cfset local.maximum = local.query['total'][1] >
				 
				<cfquery name="local.qq" dbtype="query">

					SELECT *, ( (total/#local.maximum#) *100 ) AS p
					FROM local.query
					ORDER BY tagName ASC

				</cfquery>

				<cfloop query="local.qq">

					<cfscript>
					// determine the class for this term based on the percentage
					   if ( p < 5 ) {
					   	class = 'smallest';
					   } else if ( p >= 5 and p < 20 ) {
					       class = 'small';
					   } else if ( p >= 20 and p < 50 ) {
					       class = 'medium';
					   } else if ( p >= 50 and p < 80 ) {
					       class = 'large';
					   } else {
					       class = 'largest';
					   }

					</cfscript>
					<cfset queryAddRow(local.tt)>
					<cfset querySetCell(local.tt, "tagName", local.qq.tagName)>
					<cfset querySetCell(local.tt, "total", local.qq.total)>
					<cfset querySetCell(local.tt, "percentage", int(local.qq.p))>
					<cfset querySetCell(local.tt, "frequent", class)>

				</cfloop>

			</cfif>
			<!--- // END: Any records? --->

			<cfset result.query = local.tt>	 
			<cfset result.status = true />
		 	<cfset result.message = application.messages['tagsCloud_get_found_success']>
			
			<!--- // END: Any records? --->

			 
			<cfcatch>
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage(message ='database_query_error', error = variables.cfcatch)>
				<!--- // 666, 'Database Error', 1 --->
				<cfset logAction( actionID = 666, errorCatch = variables.cfcatch, extra="method:/tagsCloud/GET")>	
				<cfreturn representationOf(result.message).withStatus(500)>

	        </cfcatch>

	    </cftry> 

		<cfset result.status = true />
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>	

</cfcomponent>