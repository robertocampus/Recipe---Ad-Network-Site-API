<cfcomponent extends="taffyAPI.base" taffy:uri="/siteAdUnits/" hint="used to store site adUnits data in the siteUnits table">

	<cffunction name="GET" access="public" output="false" hint="get site adunits data">

		<cfargument name="adUnitTypeID" type="numeric" required="true">
		<cfargument name="siteSectionID" type="numeric" required="true">
		<cfargument name="filters" 		type="struct" default="#StructNew()#" required="false">
		<cfargument name="keyWords"     type="string" default=""			  required="false">

		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />

		<cfset local['siteAdunitTemplate'] = '<script type="text/javascript">
var __fbr_pid = "502";
var __fbr_bid = "2";
var __fbr_sid = "484";
var __fbr_size = "__size__";
var __fbr_auid = "__auid__";
var __fbr_zone = ""; 
var __fbr_keywords = "__keyWords__";
</script>
<script src="#application.adsurl#" type="text/javascript"></script>'> 	

		<cftry>
			
			<cfquery name="local.query" datasource="#variables.datasource#">

				SELECT * FROM val_siteunits vs
					LEFT JOIN val_adunittype va ON va.adUnitTypeID = vs.adUnitTypeID

						WHERE vs.adUnitTypeID = <cfqueryparam value="#arguments.adUnitTypeID#" cfsqltype="cf_sql_integer">
						AND   vs.siteSectionID = <cfqueryparam value="#arguments.siteSectionID#" cfsqltype="cf_sql_integer">

					<cfif StructCount(arguments.filters) GT 0>
								
						<cfloop collection="#arguments.filters#" item="thisFilter">

							<cfif thisFilter EQ "siteLocationID" AND TRIM(arguments.filters[thisFilter]) NEQ "">
											
								AND vs.siteLocationID = <cfqueryparam value="#arguments.filters[thisFilter]#" cfsqltype="cf_sql_integer">

							<cfelseif thisFilter EQ "sitePageID" AND TRIM(arguments.filters[thisFilter]) NEQ "">

								AND vs.sitePageID =<cfqueryparam value="#arguments.filters[thisFilter]#" cfsqltype="cf_sql_integer">

							<cfelseif thisFilter EQ "entityTypeID" AND TRIM(arguments.filters[thisFilter]) NEQ "">

								AND vs.entityTypeID = <cfqueryparam value="#arguments.filters[thisFilter]#" cfsqltype="cf_sql_integer">
								
							<cfelseif thisFilter EQ "adUnitTypeID" AND TRIM(arguments.filters[thisFilter]) NEQ "">

								AND vs.adUnitTypeID = <cfqueryparam value="#arguments.filters[thisFilter]#" cfsqltype="cf_sql_integer">							
								
							<cfelseif thisFilter EQ "auid" AND TRIM(arguments.filters[thisFilter]) NEQ "">

								AND vs.auid = <cfqueryparam value="#arguments.filters[thisFilter]#" cfsqltype="cf_sql_integer">

							</cfif>

						</cfloop>

					</cfif>
			</cfquery>

			<cfcatch>		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /siteAdUnits/GET")>
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationof(result.message).withStatus(500) />	

			</cfcatch>
  		
		</cftry>

		<cfif local.query.recordCount EQ 0>

			<cfset result.message = application.messages['siteadunits_get_found_error']>
			<cfreturn nodata().withStatus(404)>

		</cfif>

		<cfset local['siteAdunitTemplate'] = ReplaceNoCase(local['siteAdunitTemplate'], "__size__", local.query.primary_Size, "ALL")>
		<cfset local['siteAdunitTemplate'] = ReplaceNoCase(local['siteAdunitTemplate'], "__auid__", local.query.auid, "ALL")>
 		<cfset local['siteAdunitTemplate'] = ReplaceNoCase(local['siteAdunitTemplate'], "__keyWords__", #arguments.keywords#, "ALL")>

		<cfset result['siteunitTemp'] = local['siteAdunitTemplate']>
		<cfset result.message = application.messages['siteadunits_get_found_success']>
		<cfset result.status = true>

		<cfreturn representationof(result).withStatus(200)>

	</cffunction>

</cfcomponent>