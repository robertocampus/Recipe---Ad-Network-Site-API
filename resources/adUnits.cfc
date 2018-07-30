<cfcomponent extends="taffyAPI.base" taffy:uri="/adUnits/" hint="Ad with their details">
	<!--- :: METHOD: getAdUnits :: --->
	<cffunction name="GET" access="public" returntype="struct" output="true" hint="Get Ad Unit by adUnitName.">
		<cfargument name="adUnitName" type="string" default="" required="no" hint="">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['message'] 	= "" />
		<cfset result['status']  	= false />
		<cfset result['error']		= ''>

		<cftry>

	  		<cfquery datasource="#variables.datasource#" name="result.query">

		    	SELECT *
				FROM val_adunittype  		
				WHERE active = 1
				
				<cfif structKeyExists(arguments, "adUnitName") AND len(arguments.adUnitName)>
					AND adUnitName = <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.adUnitName#">
				</cfif>

			</cfquery>
				 
			<cfcatch>

			    <!--- :: degrade gracefully :: --->
			   <cfset result.message = errorMessage(message='database_query_error', error = variables.cfcatch)>
			    <!--- // 666, 'Database Error', 1 --->
				<cfset local.logAction = logAction( actionID = 666, extra = "method: /adUnits/GET", errorCatch = variables.cfcatch  )>	
				<cfreturn representationOf(result.message).withStatus(500)>

	        </cfcatch>

	    </cftry> 

		<cfset result.status  	= true />
		<cfset result.message = application.messages['adUnits_get_found_success']>

	  	<cfset local.tmp = logAction( actionID = 290, extra = "method: /adUnits/GET"  )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>