<cfcomponent extends="TaffyAPI.base" taffy:uri="/sponsor/{id}" hint="sponsor endpoint is used to get a sponsor records using <code>GET</code> methods.">
	
	<!--- :: METHOD: GET :: --->

	<cffunction name="GET" access="public" hint="Return Public Sponsor DATA" output="true">
        <cfargument name="id"  		type="numeric" required="true"  hint="sponsor ID">
        <cfargument name="userID"  	type="numeric" required="false" hint="user ID">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />
  
		<cftry>
        
	 	    <cfquery datasource="#variables.datasource#" name="result.query">
	 			SELECT 
					 s.sponsorID 
					,s.sponsorName
					,s.sponsorSlug
					,s.sponsorURL
					,s.sponsorEmail
					,s.sponsorTweeterUsername
					,s.sponsorFacebook				
					,s.sponsorInstagram
					,s.sponsorPinterest
					,s.sponsorGooglePlus
					,s.sponsorContactName
					,s.sponsorCreateDate
					,s.sponsorUpdateDate
					,s.sponsorText
					,s.sponsorDescription
					,s.sponsorAboutShort
					,s.sponsorIsBrandPage
					,s.active
					,s.sponsorIsCustom
		 			,s.userID				
					,s.active
					
					,c.countryFullName
					,st.stateName
					,U.userFirstName
					,U.userLastName
					,CONCAT( i.imagePath, '/', i.imageName ) AS 'sponsor_FullSize_Image'
					,CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'sponsor_Thumb_Image'
					,CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'sponsor_mini_Image'
	 				,(SELECT count(userID) FROM users_follow WHERE entityID = s.sponsorID AND entitytypeID = 20 AND followStatus = 1) AS 'sponsor_totalFollowers'

					<cfif StructKeyExists(arguments, "userID")>
						,( SELECT GROUP_CONCAT(ff.friendID) FROM friends ff WHERE ff.friendUserID = s.userID AND ff.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#"> ) as isUserFriend
					<cfelse>
						,NULL as isUserFriend
					</cfif>
					
					,( SELECT count(*) FROM items it WHERE it.userID = s.userID AND it.active = 1 AND it.itemIsPublished = 1 AND it.itemTypeID = 7 AND ( 
							it.itemPublishDate <= now() OR it.itemPublishDate IS null ) AND ( it.itemExpireDate >= now() OR it.itemExpireDate IS null )
					) as totalPosts
					
					,( SELECT count(*) FROM contests ct WHERE ct.sponsorID = s.sponsorID AND ct.active = 1 AND ct.contestPublishDate <= now() ) as totalPromotions
					,( SELECT count(*) FROM friends f WHERE f.friendStatusID = 2 AND f.active =1 AND (f.userID = s.userID OR f.friendUserID = s.userID) ) as totalFriends				
					,(SELECT GROUP_CONCAT(tagName) FROM tags WHERE tagID IN(SELECT tagID FROM tagging WHERE entityID = s.sponsorID AND entityTypeID = 20)) AS tags
					 
				FROM sponsors s
				
				LEFT JOIN contests cs on cs.sponsorID = s.sponsorID
				
				<!---LEFT JOIN sponsors_meta sm on sm.sponsorID = s.sponsorID--->
				LEFT JOIN val_countries c on c.countryID = s.sponsorCountryID
				LEFT JOIN val_states st on st.stateID = s.sponsorStateID				
				LEFT JOIN images i on i.entityID = s.sponsorID	AND i.entitytypeID = 20
				LEFT JOIN val_sponsorcategory vsc ON vsc.sponsorCategoryID = s.sponsorCategoryID
				LEFT JOIN users U ON U.userID = s.userID		
				WHERE 1 = 1

				AND s.active = 1
				AND s.sponsorID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#" >
	            GROUP BY s.sponsorID 
			</cfquery>

			<cfquery datasource="#variables.datasource#" name="local.sponsorMetaDetails">
	 			SELECT meta_key, meta_value
				FROM sponsors_meta
				WHERE sponsorID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
	 			ORDER BY metaID ASC
	 		</cfquery>

	 		<cfset result['sponsorMetaDetails'] = [] >
			<cfset local.sponsor_meta 	 		= {}>
			
			<cfloop query="local.sponsorMetaDetails" >
				<cfset structInsert(local.sponsor_meta,"#meta_key#","#meta_value#")>				
			</cfloop>

			<cfset arrayAppend(result.sponsorMetaDetails, local.sponsor_meta)>
			
			<!--- // Any Records Found? --->
			<cfif result.query.recordCount EQ 0 >
				<cfset result.message = application.messages['sponsor_get_found_error'] />
				<cfreturn noData().withStatus(404) />
			</cfif>
		   
	  	    <cfcatch>
				
				<!--- :: degrade gracefully :: --->
			
				<cfset result.message =error.message(message = 'database_query_error', error = variables.cfcatch)>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: Sponsors GET", errorCatch = variables.cfcatch  )>	
			  	<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
		
	  	</cftry>

		<cfset result.status  	= true />
		<cfset result.message = application.messages['sponsor_get_found_success'] />

	  	<cfset local.tmp = logAction( actionID = 1015, extra = "method: /Sponsors/{id}/GET"  )>

	  	<cfreturn representationOf(result).withStatus(200) />
	</cffunction>	

</cfcomponent>