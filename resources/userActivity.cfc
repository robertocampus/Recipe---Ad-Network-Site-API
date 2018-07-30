<cfcomponent extends="taffyAPI.base" taffy_uri="/userActivity/" hint="Using this user can able to <code>GET</code> user activity details">

<cffunction name="GET" access="public" hint="Return user activity by filters" returntype="struct" output="true">

		<cfargument name="filters" type="struct" default="#StructNew()#" required="false" hint="Listing Filters struct">
		<cfargument name="pagination"  type="struct" default="#StructNew()#" required="false" hint="Listing Paging struct">
        <cfargument name="cache"   type="string" default="1" 		 	 required="false" hint="Query Cache Lenght">		
	 
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result.status  	= false />
		<cfset result.message 	= "" />
		<cfparam name="arguments.pagination.orderCol" default="id">
		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);

		</cfscript>
		<cftry>
  		
			<cfquery datasource="#variables.datasource#" name="result.query"> 
			   SELECT SQL_CALC_FOUND_ROWS
					a.id,
					a.userID,
					a.component,
					a.action,
					a.activityID,
					a.activityType,
					a.typeID,
					a.content,
					a.excerpt,
					a.primary_link,
					a.objectID,
					a.s_objectID,
					a.createDate,
					a.isVisibleSiteWide,
					u.username,
					u.userAvatarURL	
				FROM activity a
				INNER JOIN users u ON u.userID = a.userID
				
	  			WHERE 1 = 1
				
				<!--- ADD FILTERS TO QUERY  --->
				<cfif StructCount(arguments.filters) GT 0>
					
	  				<cfloop collection="#arguments.filters#" item="thisFilter">
					 
						<!--- SEARCH --->	
						<cfif		thisFilter EQ "component" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND a.component LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#arguments.filters[thisFilter]#%">

						<cfelseif	thisFilter EQ "action" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND a.action LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#arguments.filters[thisFilter]#%">

						<cfelseif	thisFilter EQ "activityType" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND a.activityType LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#arguments.filters[thisFilter]#%">

						<cfelseif	thisFilter EQ "activityID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND a.activityID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#" list="yes"> )

						<cfelseif	thisFilter EQ "typeID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND a.typeID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#" list="yes"> )


						<cfelseif	thisFilter EQ "objectID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND a.objectID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#" list="yes"> )

						<cfelseif	thisFilter EQ "s_ObjectID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND a.s_objectID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#" list="yes"> )
	 
						<cfelseif	thisFilter EQ "userID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND a.userID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#" list="yes"> )

						<cfelseif	thisFilter EQ "isVisibleSiteWide" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND a.isVisibleSiteWide IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#" list="yes"> )
												 
					<!--- OTHER FLAGS --->
						-- <cfelseif	 arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
						-- 	AND t.#thisFilter# = #val(arguments.filters[thisFilter])# 
						-- </cfif>
					
					</cfloop>					
							
				</cfif>
	 			
	           ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir# limit #arguments.pagination.offset#, #arguments.pagination.limit# 

			</cfquery>
			
			<cfquery datasource="#variables.datasource#" name="result.rows">

			SELECT FOUND_ROWS() AS total_count;

			</cfquery>
			 
			
			<!--- // Found? --->
			<cfif result.query.recordCount EQ 0>

				<cfset result.status = false />
				<cfset result.message = application.messages['userActivity_get_found_error']>
			 	<cfreturn noData().withStatus(404)>

			</cfif>				
	   
			<cfcatch>
			
				<!--- :: degrade gracefully :: --->

				<cfset result.message = errorMessage( message ='database_query_error', error = variables.cfcatch)>

				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /UserActivity/GET", errorCatch = variables.cfcatch  )>	
				<cfreturn representationOf(result.message).withStatus(500)>

			</cfcatch>
		
	  	</cftry>

	  	<cfset result.status = true>
	  	<cfset result.message = application.messages['userActivity_get_found_success']>
	  	<!--- <cfset logAction( actionID = 661, extra = "method: /UserActivity/GET", errorCatch = variables.cfcatch  )> --->
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>