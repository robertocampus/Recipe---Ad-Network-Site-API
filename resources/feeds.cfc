<cfcomponent extends="taffyAPI.base" taffy_uri="/feeds/" hint="Using this user can able to <code>GET</code> feeds details">

	<cffunction name="GET" access="public" hint="Return Blog Feed Items" returntype="struct" output="true">
		<cfargument name="filters" 		type="struct" default="#StructNew()#" required="false" hint="Listing Filters struct">
		<cfargument name="pagination"  	type="struct" default="#StructNew()#" required="false" hint="Listing Paging struct">
        <cfargument name="cache"   type="string" default="1" 		 	 required="false" hint="Query Cache Lenght">		
		 
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />

		<cfparam name="arguments.pagination.orderCol" default="feedID">
		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);

		</cfscript>

		<cftry>
  		
			<cfquery datasource="#variables.datasource#" name="result.query"> 
			   SELECT SQL_CALC_FOUND_ROWS
					f.feedID,
					f.id,
					f.blogID, 
					f.title, 
					f.publisheddate, 
					LEFT(f.content,255) AS content,
					f.link,
					f.postLink,
					b.blogTitle,
					b.blogSlug,
					b.blogThumbnailStatus, 
	  				ub.userID
				FROM feeds f
				INNER JOIN blogs b ON b.blogID = f.blogID
				INNER JOIN userblogs ub ON ub.blogID = f.blogID
				WHERE f.active = 1
				AND f.content IS NOT NULL
	        	AND f.content <> ""
				AND b.active = 1
				AND b.statusID = 3
				
				<!--- ADD FILTERS TO QUERY  --->
				<cfif StructCount(arguments.filters) GT 0>
					
	  				<cfloop collection="#arguments.filters#" item="thisFilter">
					 
						<!--- SEARCH --->	
						<cfif		thisFilter EQ "Text" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND f.title LIKE <cfqueryparam cfsqltype="cf_sql_string" value="%#arguments.filters[thisFilter]#%">
	 
						<cfelseif	thisFilter EQ "BlogID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND f.blogID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#" list="yes"> )
						
						<cfelseif	thisFilter EQ "CountryID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND b.countryID = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#">	

						<cfelseif	thisFilter EQ "LanguageName" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND b.languageID = ( SELECT languageID from val_language WHERE languagename = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#"> LIMIT 1 )						
						
						<cfelseif thisFilter EQ "userID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND ub.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

						</cfif>
					
					</cfloop>					
							
				</cfif>
	 			
           		ORDER BY f.#arguments.pagination.orderCol# #arguments.pagination.orderDir# limit #arguments.pagination.offset#, #arguments.pagination.limit# 
				
			</cfquery>
			
			<cfquery datasource="#variables.datasource#" name="result.rows" cachedwithin="#CreateTimeSpan(0,0,10,0)#">
				SELECT FOUND_ROWS() AS total_count;
			</cfquery>
			 
			<!--- // Found? --->
			<cfif result.query.recordCount EQ 0>

				<cfset result.message = application.messages['feeds_get_found_error']>
				<cfset result.status = false />
				<cfreturn representationOf(result).withStatus(404)>

			</cfif>				
		   
			<cfcatch>
			
			  	<!--- :: degrade gracefully :: --->
			  	<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
			
			  	<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
			  	<cfset logAction( actionID = 661, extra = "method:/Feeds/GET", errorCatch = variables.cfcatch  )>	
	 		  	<cfset representationOf(result.message).withStatus(500)>

			</cfcatch>
			
		</cftry>

		<cfset result.status = true>
		<cfset result.message = application.messages['feeds_get_found_success']>
		<cfset logAction( actionID = 661, extra = "method:/Feeds/GET")>
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>	

</cfcomponent>
