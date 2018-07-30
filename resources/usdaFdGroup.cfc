<cfcomponent extends="taffyAPI.base" taffy:uri="/usdaFdGroup/" hint="By using this user can get data from usda-fd-group table">
	
	<cffunction name="GET" access="public" hint="Return the data form usda-fd-group table">
		<cfargument name="filters" type="struct" required="false" default="#structNew()#" >
		<cfargument name="pagination" type="struct" required="false" default="#structNew()#" >

		<cfset result=structNew()>
		<cfset result['status'] = false>
		<cfset result['message'] = "">

		<cfparam name="arguments.pagination.orderCol" type="string" default="fdGrp_CD"/>
		<cfset arguments.pagination = checkPagination(arguments.pagination)>

		<cftry>
			
			<cfquery name="result.query" datasource="#variables.datasource#">

				SELECT * FROM usda_fd_group
				WHERE 1 = 1 

				<cfloop collection="#arguments.filters#" item="thisFilter">
					
					<cfif thisFilter EQ "FdGrp_CD" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND FdGrp_CD = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

					<cfelseif thisFilter EQ "FdGrp_Desc" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND FdGrp_Desc LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">

					</cfif>


				</cfloop>

				ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir# limit #arguments.pagination.offset#, #arguments.pagination.limit# 

			</cfquery>

			<cfif result.query.recordCount EQ 0 >
				<cfset result.message = application.messages['tagsCloud_get_found_error']>
				<cfreturn noData().withStatus(404) />

			</cfif>

			<cfcatch>		

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch )>
				<cfset logAction( actionID = 661, extra = "method: /usdaFdGroup/GET", errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />	
				
		  	</cfcatch>
	
  		</cftry>   
		
		<cfset result.status  	= true />
		<cfset result.message = application.messages['tagsCloud_get_found_success']>
		
	  	<cfset logAction( actionID = 2004, extra = "method: /usdaFdGroup/GET" )>

		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>

</cfcomponent>