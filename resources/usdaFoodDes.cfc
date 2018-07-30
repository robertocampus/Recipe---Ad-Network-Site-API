<cfcomponent extends="taffyAPI.base" taffy:uri="/usdaFoodDes/" hint="By using this user can get data from usda food desc table">
	
	<cffunction name="GET" access="public" hint="Return the data form usda food desc table">
		<cfargument name="filters" type="struct" required="false" default="#structNew()#" >
		<cfargument name="pagination" type="struct" required="false" default="#structNew()#" >

		<cfset result=structNew()>
		<cfset result.status = false>
		<cfset result.message = "">

		<cfparam name="arguments.pagination.orderCol" type="string" default="ufd.NDB_No"/>
		<cfset arguments.pagination = checkPagination(arguments.pagination)>

		<cftry>
			
			<cfquery name="result.query" datasource="#variables.datasource#">

				SELECT * FROM usda_food_des ufd
					LEFT JOIN usda_fd_group ufg ON ufg.FdGrp_CD = ufd.FdGrp_Cd
					LEFT JOIN usda_nut_data und ON und.NDB_No = ufd.NDB_No
					LEFT JOIN usda_weight uw ON uw.NDB_No = ufd.NDB_No
					LEFT JOIN usda_footnote ufn ON ufn.NDB_No = ufd.NDB_No
					LEFT JOIN usda_langual ul ON ul.NDB_No = ufd.NDB_No
				WHERE 1 = 1 
				
				<cfloop collection="#arguments.filters#" item="thisFilter">
					
					<cfif thisFilter EQ "NDB_No" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.NDB_No = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

					<cfelseif thisFilter EQ "FdGrp_Cd" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.FdGrp_Cd = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

					<cfelseif thisFilter EQ "Long_Desc" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.Long_Desc LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">

					<cfelseif thisFilter EQ "Shrt_Desc" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.Shrt_Desc LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">

					<cfelseif thisFilter EQ "ComName" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.ComName LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">

					<cfelseif thisFilter EQ "ManufacName" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.ManufacName LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">

					<cfelseif thisFilter EQ "Survey" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.Survey LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">

					<cfelseif thisFilter EQ "Ref_Desc" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.Ref_Desc LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">

					<cfelseif thisFilter EQ "Refuse" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.Refuse = <cfqueryparam cfsqltype="cf_sql_smallint" value="#arguments.filters[thisFilter]#">

					<cfelseif thisFilter EQ "SciName" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.SciName LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">

					<cfelseif thisFilter EQ "N_Factor" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.N_Factor = <cfqueryparam cfsqltype="cf_sql_double" value="#arguments.filters[thisFilter]#">

					<cfelseif thisFilter EQ "Pro_Factor" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.Pro_Factor = <cfqueryparam cfsqltype="cf_sql_double" value="#arguments.filters[thisFilter]#">

					<cfelseif thisFilter EQ "Fat_Factor" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.Fat_Factor = <cfqueryparam cfsqltype="cf_sql_double" value="#arguments.filters[thisFilter]#">

					<cfelseif thisFilter EQ "CHO_Factor" AND TRIM(arguments.filters[thisFilter]) NEQ "">

						AND ufd.CHO_Factor = <cfqueryparam cfsqltype="cf_sql_double" value="#arguments.filters[thisFilter]#">

					</cfif>


				</cfloop>


				ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir# limit #arguments.pagination.offset#, #arguments.pagination.limit# 
			</cfquery>

			<cfif result.query.recordCount EQ 0 >
				<cfset result.message = application.messages['usdafooddes_get_found_error']>
				<cfreturn noData().withStatus(404) />
			</cfif>

			<cfcatch>	
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>	
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /usdaFoodDes/GET", errorCatch = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />	
		  	</cfcatch>
	
  		</cftry>   
		
		<cfset result.status  	= true />
		<cfset result.message = application.messages['usdafooddes_get_found_success']>
		

	  	<cfset logAction( actionID = 2004, extra = "method: /usdaFoodDes/GET" )>

		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>

</cfcomponent>