<cfcomponent extends="taffyAPI.base" taffy_uri="/programs/" hint="Using this user can able to <code>Get</code> a list of programs.<br/> <code>Post</code> is used to create a new program record.">

	<cffunction name="GET" access="public" hint="Return Ad Units DATA" returntype="struct" output="true">
		<cfargument name="filters" 		type="struct" default="#StructNew()#" required="false" hint="Recipe Listing Filters struct">
		<cfargument name="pagination"	type="struct" default="#StructNew()#" required="false" hint="Recipe Listing pagination struct">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "">
		<cfset result['error']   =true>
		<cfparam name="arguments.pagination.orderCol" default="programID">
		
		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);

		</cfscript>

		<cftry>
			
		
	  		<cfquery datasource="#variables.datasource#" name="result.query">

		    	SELECT SQL_CALC_FOUND_ROWS
		    	bp.*,
		    	vp.programSiteStatusName
				
				FROM blog_programs bp
				LEFT JOIN val_programsitestatus vp ON vp.programSiteStatusID = bp.siteStatusID
				
				WHERE 1 = 1
				
				<!--- ADD FILTERS TO QUERY  --->
				<cfif StructCount(arguments.filters) GT 0>
					
	  				<cfloop collection="#arguments.filters#" item="thisFilter">
					 
						<!--- SIMPLE SEARCH on Test Name --->	
						<cfif		thisFilter EQ "BlogID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND bp.blogID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="true"> )

						<cfelseif	thisFilter EQ "UserID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND bp.userID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="true"> )
							
						<cfelseif	thisFilter EQ "ProgramID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND bp.programID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="true"> )
						
						<cfelseif	thisFilter EQ "isActive" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND bp.active IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="true"> )
							
						<cfelseif	thisFilter EQ "SiteStatusID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
							AND bp.siteStatusID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="true"> )	
						
						<!--- OTHER FLAGS --->
						-- <cfelseif	 arguments.filters[thisFilter] NEQ 0 AND isNumeric(arguments.filters[thisFilter])>
						-- 	AND #thisFilter# = #val(arguments.filters[thisFilter])#
						-- </cfif>
					
					</cfloop>					
							
				</cfif>
				
				ORDER BY #arguments.pagination.orderCol# #arguments.pagination.orderDir# LIMIT #arguments.pagination.offset#, #arguments.pagination.limit#
	            
	   		</cfquery>
	 		
			<cfquery datasource="#variables.datasource#" name="result.rows">
				SELECT FOUND_ROWS() AS total_count;
			</cfquery>
  		 
	  		<!--- Any records? ---> 
	  		<cfif NOT result.query.recordCount >
	  			<cfset result.message = application.messages['programs_get_found_error']>
	  			<!--- <cfset logAction( actionID = 661, userID = 1, errorCatch = variables.cfcatch  )>	 --->
				<cfreturn noData().withStatus(404)>

	  		</cfif>
		   
			 
			<cfcatch>
			    <!--- :: degrade gracefully :: --->
			   
	  			<cfset result.message = errorMessage(message = 'programs_get_found_error', error = variables.cfcatch)>
			      
			    <!--- // 8505, Error occured While Getting all program --->
				<cfset logAction( actionID = 8505, userID = 1, errorCatch = variables.cfcatch  )>	
				<cfreturn representationOf(result.message).withStatus(500) />
			  
	        </cfcatch>
			
	    </cftry> 

	    <cfset result.status = true>
	  	<cfset result.message = errorMessage( message = 'programs_get_found_success')>
	   
	    <!--- 8506: all program record were got --->
	    <!--- <cfset logAction( actionID = 8506, userID = 1, errorCatch = variables.cfcatch  )> --->
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>


	<cffunction name="POST" access="public" hint="Insert Blog Program DATA" returntype="struct" output="true">
		<cfargument name="programID"			type="string" 	required="true"	hint="Program ID">
		<cfargument name="blogID"				type="string" 	required="true"	hint="Blog ID">
		<cfargument name="userID"				type="string" 	required="true"  hint="User ID"> 
		<cfargument name="siteStatusID"			type="string"  required="false"    default="2"  hint="Site Program Status ID">
		<cfargument name="external_id"			type="string" 	required="false"   default="0"	hint="External ID">

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset var local = StructNew() />

		<cfset result['status'] = false />
		<cfset result['message'] = ''>

		<cftry>

			<cfquery datasource="#variables.datasource#" name="local.query" result="qry">

				INSERT INTO blog_programs 
							(
								programID,
								blogID,
								userID,
								dateCreated,
								siteStatusID,
								external_id,
								active
							)
				VALUES   (
							<cfqueryparam cfsqltype="cf_sql_integer" 	value="#arguments.programID#">,
							<cfqueryparam cfsqltype="cf_sql_integer" 	value="#arguments.blogID#">,
							<cfqueryparam cfsqltype="cf_sql_integer" 	value="#arguments.userID#">,
							<cfqueryparam cfsqltype="cf_sql_timestamp" 	value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >,
							<cfqueryparam cfsqltype="cf_sql_integer"   	value="#arguments.siteStatusID#">,
							<cfqueryparam cfsqltype="cf_sql_integer" 	value="#arguments.external_id#">,
							<cfqueryparam cfsqltype="cf_sql_integer"	value="1">
						)

			</cfquery>
			
			<cfset result.id = qry.GENERATED_KEY>
			<cfset reuslt.error = false>

			<cfcatch>
				
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage( message = 'programs_post_add_error', error = variables.cfcatch)> 
		
				<!--- // 8507, 'Error: Error while inserting new program record --->
				<cfset logAction( actionID = 8507, extra = "method: /programs/POST", errorCatch = variables.cfcatch  )>	
			  	<cfset representationOf(result.message).withStatus(500)>

			</cfcatch>
		
	   </cftry>

	   	<cfset result.status = true>
	   	<cfset result.message = application.messages['programs_post_add_success']>

		<cfset logAction( actionID = 8508, extra = "method: /programs/POST")>	
		<cfreturn representationOf(result).withStatus(200)>

	</cffunction>
	 
</cfcomponent>