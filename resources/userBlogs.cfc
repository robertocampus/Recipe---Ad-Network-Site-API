<cfcomponent extends="taffyAPI.base" taffy:uri="/userBlogs/{userID}" hint="Using this user can able to <code>Get</code> a single user's blogs details by passing userID.">
	
	<cffunction name="GET" access="public" output="false" hint="To GET the user's Blogs">

		<cfargument name="userID" type="numeric" required="true" hint="userID">	
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  	= false />
		<cfset result['message'] 	= "" />

		<cftry>
		    <cfset local.timeStamp = "#DateFormat(now(), "YYYY-MM-DD")# #TimeFormat(now(), " HH:MM:SS")#">
			<cfquery name="result.query" datasource="#variables.datasource#">
			
		      SELECT  
			    		b.blogID,
			    		b.blogTitle,
			    		b.blogURL,
			    		b.blogSlug,
			    		b.blogDescription,
			    		b.blogTags,
			    		b.publisherStatusID,
			    		b.isBeacon,
			    		b.isTal,
			    		b.statusID,
			    		b.publisherDateApproved,
			    		b.privacyPolicyURL,
			    		b.blogRSS,
			    		b.facebookPageURL,
						(SELECT statusName FROM val_status WHERE statusID = b.statusID) AS 'statusname',
						U.userID,
						U.userName AS authorUserName,
						U.userFirstName AS authorFirstName,
						U.userLastName AS authorLastName,
						b.blogDateCreated,
						b.hits AS widgetHitCount,
						b.active,
						(SELECT countryName FROM val_countries WHERE countryID = b.countryID) AS 'countryname',
						(SELECT languagename FROM  val_language WHERE languageID = b.languageID)AS 'languagename',
						CONCAT( i.imagePath, '/', i.imageName ) AS 'blog_FullSize_Image',
						CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'blog_Thumb_Image',
						CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'blog_mini_Image'
						,( SELECT count FROM entityViewsCount WHERE entityID = b.blogID AND entityTypeID = 3) AS 'popularity' 
						,(SELECT count(userID) FROM users_follow WHERE entityID = b.blogID AND entitytypeID = 3 AND followStatus = 1 ) AS 'blog_totalFollowers'
						
					FROM blogs b
					
					INNER JOIN userblogs UB ON UB.blogID   = b.blogID
					INNER JOIN users U  ON U.userID    = UB.userID
					LEFT JOIN images i on i.entityID = b.blogID AND i.entityTypeID = 3
					WHERE 1 = 1 
					AND UB.userID =<cfqueryparam value="#arguments.userID#" cfsqltype="cf_sql_integer">
				GROUP BY b.blogID
		   </cfquery>

		  	<cfcatch>				
				<!--- :: degrade gracefully :: --->
				<cfset result.message = errorMessage(message = 'database_query_error', error = variables.cfcatch)>
		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset local.logAction = logAction( actionID = 661, extra = "method: /blog/{id}/GET", errorCatch = variables.cfcatch  )>	
			  
			  	<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
		
	    </cftry>

	    <cfif result.query.recordCount LT 1>
	    	<cfset result.message  = application.messages['userBlogs_get_found_error']>
	    	<cfreturn noData().withStatus(404)>
	    </cfif>


	    <cfset local.userSocialDetails = application.accountObj.getUserSocialDetails(result.query.userID)>

		<cfif local.userSocialDetails.status EQ true>
			<cfset result.userSocialDetails = local.userSocialDetails.dataset>
		<cfelse>
			<cfset result.userSocialDetails = []>
		</cfif>

	    <cfset result.status  	= true />
	    <cfset result.message = application.messages['userBlogs_get_found_success'] />

	   	 <!--- 211:: Success:: blogs details has been retrived successfully --->
	  	<cfset  logAction( actionID = 211, extra = "method: /userBlogs/{userID}/GET"  )>

		<cfreturn representationOf(result).withStatus(200) />

	</cffunction>

</cfcomponent>
