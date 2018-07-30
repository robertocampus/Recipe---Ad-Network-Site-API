<cfcomponent extends="taffyAPI.base" taffy:uri="/program/" hint="Using this user can able to <code>Get</code> a single program by passing programID. Can also able to <code>Update</code> an existing program using programID.">

	<cffunction name="GET" access="public" hint="Return Publisher Blog and Tag Meta DATA" returntype="struct" output="true">
		<cfargument name="programID"  	type="string"  required="true"  hint="program ID">

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset var local = StructNew() />

		<cfset result['status'] = false />
		<cfset result['message'] = ''>

		<cftry>

			<cfquery datasource="#variables.datasource#" name="result.query">
				SELECT * 
				FROM val_programs
				WHERE 1 = 1
				AND programID IN ( <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.programID#"> )
				ORDER BY programID ASC
			</cfquery>

			<!--- Any records? ---> 
	  		<cfif NOT result.query.recordCount >
	  			<cfset result['message'] = application.messages['program_get_found_error']>
				<cfreturn noData().withStatus(404)>

	  		</cfif>
					
			<cfcatch>
				
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
				<cfset logAction( actionID = 661, extra = "method: /program/GET", errorCatch = variables.cfcatch )>
			  	<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
	   	</cftry>

		<!--- 8502: success program records were got --->
		<cfset logAction( actionID = 8502, extra = "method: /program/GET")>
		<cfset result.status = true>
		<cfset result.message = application.messages['program_get_found_error']>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

	<cffunction name="PUT" access="public" hint="Update Blog Program DATA" returntype="struct" output="true">

		<cfargument name="userID"  		type="string"  required="true" hint="User ID">
		<cfargument name="blogID"  		type="string"  required="true" hint="Blog ID">
		<cfargument name="programID"  	type="string"  required="true" hint="Program ID">
		<cfargument name="active"  		type="string"  required="true" hint="Active (1/0)">
		<cfargument name="siteStatusID"	type="string"  required="false"  hint="Site Program Status ID">
		<cfargument name="external_id"	type="string"  required="false"  hint="External ID">

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset var local = StructNew() />

		<cfset result['status'] = false />
		<cfset result['message'] = ''>

		<cftry>

			<cfquery datasource="#variables.datasource#" name="local.query">

				UPDATE blog_programs
				   SET active = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.active#">,
				   
				   <cfif StructKeyExists(arguments, "siteStatusID")>
				   
					   	siteStatusID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.siteStatusID#">,
		 
					   	<cfif arguments.siteStatusID EQ 3>
							dateEnrolled = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >,
					   	</cfif>
					   
					   	<cfif arguments.siteStatusID EQ 5>
							dateSuspended = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >,
					   	</cfif>
					   
				  	</cfif>

				   	<cfif StructKeyExists(arguments, "external_id")>
				 	  	external_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.external_id#">,
				   	</cfif>

				   	dateModified =<cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >

				WHERE userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
				   	AND blogID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#">
				   	AND programID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.programID#">

			</cfquery>
			
			<cfset result.message = application.messages['program_put_update_success']>
			<cfset result.status = true />

			<cfcatch>
				
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
		
				<!--- // 8503, 'Error while updating program record. --->
				<cfset logAction( actionID = 8503, extra = "method: /program/PUT", errorCatch = variables.cfcatch  )>	
			  	<cfreturn representationOf(result.message).withStatus(500) />

			</cfcatch>
		
	   </cftry>

	    <!--- 8504:Program record have been successfully updated. --->
	    <cfset logAction( actionID = 8504, extra = "method: /program/PUT" )>
		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>

