<cfcomponent extends="taffyAPI.base" taffy:uri="/influencer/{id}" output="true" hint="influencer is used to get the user details">
	
	<cffunction name="GET" access="public" returntype="Struct" output="false" hint="Get users details by userID">
		<cfargument name="id" type="numeric" required="true" hint="userID to search">		
		
		<cfset result=structNew()>
		<cfset result['status'] = false>
		<cfset result['message'] = "">

		<cftry>

			<cfquery name="result.query" datasource="#variables.datasource#">
				
				SELECT 	u.userID
						,u.userName 
						,u.userEmail
						,u.userFirstName
						,u.userLastName
						,CASE u.userGender	
							WHEN '0' THEN 'N/A'	
							WHEN 'M' THEN 'Male'
							WHEN 'F' THEN 'Female'
						END AS userGenderName
						,CONCAT_WS(',',l.locationName,vr.roleName,vs.stateName,vs.stateCode,c.countryFullName) AS 'userAddress'
						,u.userPhone1
						,vs.stateName
						,c.countryFullName
						,u.userAbout 
						,u.userDateBirth
						,( SELECT COUNT(*) FROM users_follow WHERE entityTypeID = 4 and entityID = u.userID) AS userTotalFollowers
						,CONCAT( i.imagePath, '/', i.imageName ) AS 'user_FullSize_Image'
						,CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'user_Thumb_Image'
						,CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'user_mini_Image'
						,u.userDateRegistered
						,(SELECT meta_value FROM influencers_meta WHERE userID = u.userID AND meta_key = 'about' ) AS 'about'
						,(SELECT meta_value FROM influencers_meta WHERE userID = u.userID AND meta_key = 'bio' ) AS 'bio'
						,(SELECT meta_value FROM influencers_meta WHERE userID = u.userID AND meta_key = 'score' ) AS 'score'
						,(SELECT meta_value FROM influencers_meta WHERE userID = u.userID AND meta_key = 'experience' ) AS 'experience'
						,(SELECT REPLACE(meta_value, CHAR(7), ':::' ) FROM influencers_meta WHERE userID = u.userID AND meta_key = 'award' ) AS 'award'
						,(SELECT REPLACE(meta_value, CHAR(7), ':::' ) FROM influencers_meta WHERE userID = u.userID AND meta_key = 'media' ) AS 'media'
						,(SELECT meta_value FROM influencers_meta WHERE userID = u.userID AND meta_key = 'status_availability' ) AS 'status_availability'
						,(SELECT meta_value FROM influencers_meta WHERE userID = u.userID AND meta_key = 'status_location_city' ) AS 'status_location_city'
						,(SELECT meta_value FROM influencers_meta WHERE userID = u.userID AND meta_key = 'status_location_country' ) AS 'status_location_country'
						,(SELECT meta_value FROM influencers_meta WHERE userID = u.userID AND meta_key = 'status_location_state' ) AS 'status_location_state'
						,(SELECT meta_value FROM influencers_meta WHERE userID = u.userID AND meta_key = 'status_visibility' ) AS 'status_visibility'
						,(SELECT meta_value FROM influencers_meta WHERE userID = u.userID AND meta_key = 'title' ) AS 'title'
						,(SELECT max(meta_value) FROM users_meta WHERE meta_key = 'user_total_followers' AND userID = u.userID ) AS 'user_total_followers'
						,(select max(meta_value) from users_meta um WHERE um.userID = u.userID AND um.meta_key = 'user_total_posts')AS 'user_total_posts'
						,(select max(meta_value) from users_meta um WHERE um.userID = u.userID AND um.meta_key = 'influencer_experience')AS 'influencer_experience'
						,(select max(meta_value) from users_meta um WHERE um.userID = u.userID AND um.meta_key = 'influencer_industry')AS 'influencer_industry'
						,(SELECT count(r.recipeID) from recipes r WHERE r.userID = u.userID) AS 'user_total_recipes'
						,(SELECT count(userID) FROM users_follow WHERE entityID = u.userID AND entitytypeID = 4 AND followStatus = 1) AS 'influencer_totalFollowers'
						,(SELECT GROUP_CONCAT( DISTINCT t.tagName SEPARATOR ':::') FROM tags AS t INNER JOIN tagging AS tg ON tg.tagID = t.tagID WHERE tg.entityID = u.userID AND tg.entityTypeID = 30 ) AS 'skills'
						,(SELECT GROUP_CONCAT( DISTINCT vio.optionName SEPARATOR ':::') FROM influencers_options AS io INNER JOIN val_influencer_options AS vio ON io.optionID = vio.optionID WHERE io.userID = u.userID AND io.optionTypeID = 1 ) AS 'participate_in_most'
				FROM users u 

				LEFT JOIN val_countries c ON c.countryID = u.userCountryID
				LEFT JOIN val_states vs ON vs.stateID = u.userStateID
				LEFT JOIN val_location l ON l.locationID = u.locationID
	            LEFT JOIN val_role vr ON vr.roleID = u.roleID
	            LEFT JOIN images i ON i.entityID = u.userID AND i.entityTypeID = 4 AND i.active = 1
					WHERE  u.userID = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
						AND u.influencerStatusID = <cfqueryparam value="3" cfsqltype="cf_sql_integer">
				GROUP BY u.userID

			</cfquery>

			<cfif result.query.recordcount EQ 0 OR ( result.query.recordcount AND ( result.query.status_visibility EQ '' OR result.query.status_visibility EQ 0 ) ) >
				<cfset result.message = application.messages['influencer_get_found_error']>

				<cfreturn representationOf(result).withStatus(404)>

			</cfif>
			
			<cfcatch>

				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>
				<cfset logAction( actionID=661 , extra = "method: /influencer/{userID}", errorCatch = variables.cfcatch )>
				<cfreturn representationOf(result.message).withStatus(500)>

			</cfcatch>

		</cftry>

		<cfset result.status = true>

		<!--- //Getting userSocialDetails --->
		<cfset local.userSocialDetails = application.accountObj.getUserSocialDetails(result.query.userID)>

		<cfif local.userSocialDetails.status EQ true>
			<cfset result.userSocialDetails = local.userSocialDetails.dataset>
		<cfelse>
			<cfset result.userSocialDetails = []>
		</cfif>

		<cfset result.message = application.messages['influencer_get_found_success']>
		<cfset logAction( actionID=101 , extra = "method: /influencer/{userID}" )>
		<cfreturn representationOf( result ).withStatus(200)/>

	</cffunction>

</cfcomponent>