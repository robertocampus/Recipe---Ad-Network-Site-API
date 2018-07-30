<cfcomponent extends="taffyAPI.base" taffy:uri="/entityCount/" hint="Used to <code>GET</code> the Categories name & count of the promotions, items or news and sponsors.">
	
	<cffunction name="GET" access="public" output="false" hint="To Get entitycount">
		
		<cfargument name="entityName" type="string" required="true" hint="entityname to get entitycount">

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />

		<cfswitch expression="#arguments.entityName#">

			<cfcase value="promotions">

				<cftry>
					
					<cfquery name="result.query" datasource="#variables.datasource#">

						SELECT count(*) AS total, vc.contestTypeName AS name, c.contestTypeID AS entityTypeID
							FROM val_contesttype vc
							INNER JOIN contests c ON c.contestTypeID = vc.contestTypeID AND c.active = 1 
							WHERE vc.active = 1
							GROUP BY vc.contestTypeID
							ORDER BY vc.contestTypeName ASC	

					</cfquery>

					<cfcatch>

						<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
						<cfreturn representationOf( result.message ).withStatus(500) />

					</cfcatch>

				</cftry>

				<cfset result.status = true>
				<cfset result.message = application.messages['entityCount_get_found_success']>
				<cfreturn representationOf(result).withStatus(200)>


			</cfcase>

			<cfcase value="news">

				<cftry>
					
					<cfquery name="result.query" datasource="#variables.datasource#">

						SELECT COUNT(*) AS total, vi.itemTypeName AS name, i.itemTypeID AS entityTypeID
							FROM val_itemtype vi
							INNER JOIN items i ON i.itemTypeID = vi.itemTypeID AND i.active = 1 
							WHERE vi.active = 1
							AND i.itemIsPublished = 1
							GROUP BY vi.itemTypeID
							ORDER BY vi.itemTypeName ASC
							
					</cfquery>

					<cfcatch>
						<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
						<cfreturn representationOf(result.message).withStatus(500) />
					</cfcatch>

				</cftry>

				<cfset result.status = true>
				<cfset result.message = application.messages['entityCount_get_found_success']>
				<cfreturn representationOf(result).withStatus(200)>


			</cfcase>

			<cfcase value="sponsors">

				<cftry>
					
					<cfquery name="result.query" datasource="#variables.datasource#">

						SELECT COUNT(*) AS total, vs.sponsorCategoryName AS name , s.sponsorCategoryID AS entityTypeID
							FROM val_sponsorcategory vs
							INNER JOIN sponsors s ON s.sponsorCategoryID = vs.sponsorCategoryID AND s.active = 1 AND s.sponsorIsBrandPage = 1
							WHERE vs.active = 1 
							GROUP BY vs.sponsorCategoryID
							ORDER BY vs.sponsorCategoryName ASC
							
					</cfquery>

					<cfcatch>

						<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
						<cfreturn representationOf(result.message).withStatus(500) />

					</cfcatch>

				</cftry>

				<cfset result.status = true>
				<cfset result.message = application.messages['entityCount_get_found_success']>
				<cfreturn representationOf(result).withStatus(200)>


			</cfcase>

		</cfswitch>


	</cffunction>

</cfcomponent>
