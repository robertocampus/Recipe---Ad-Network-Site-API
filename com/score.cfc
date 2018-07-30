<cfcomponent extends="taffyAPI.base" displayname="score" hint="cfc is used to calculate the score for the form data.">
	
	<cffunction name="getInfluencerScore" returntype="Numeric" access="public" >
		<cfargument name="userID" type="numeric" required="true">

		<cfset var initialScore = 0 >
		
		<cfset metaColumn = "status_visibility,status_availability,status_location_city,status_location_state,status_location_country,title,about,bio,experience,media,award,freq_post,freq_review,freq_post_social,freq_post_video,meat_dairy,freq_cook,interest_organic,freq_tea,freq_coffee,freq_soda,freq_alcohol,rate_eco,age,income,children,education,ethnicity" >

		<cfset influencerMetaQuery  = application.influencerMetaObj.getInfluencerMeta( meta_key = metaColumn, userID = arguments.userID ) >
		<cfset influencerMeta = queryToStruct( query = influencerMetaQuery , keyCol = 'meta_key' , valueCol = 'meta_value' ) >

		<cfif structKeyExists(influencerMeta, "status_visibility") AND influencerMeta.status_visibility EQ 0 >
			<cfreturn initialScore >
		</cfif>

		<cfset initialScore += ( structKeyExists(influencerMeta, "status_availability") 		AND influencerMeta.status_availability  	NEQ 0 ) ? 5 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "status_location_city") 		AND influencerMeta.status_location_city  	NEQ 0 ) ? 1 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "status_location_state") 		AND influencerMeta.status_location_state  	NEQ 0 ) ? 1 : 0	>
		<cfset initialScore += ( structKeyExists(influencerMeta, "status_location_country") 	AND influencerMeta.status_location_country  NEQ 0 ) ? 1 : 0  >
		
		<cfset initialScore += ( structKeyExists(influencerMeta, "title") 	    AND len(influencerMeta.title)  		  GTE 3  ) ? 5 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "about") 	    AND len(influencerMeta.about)  		  GTE 3  ) ? 5 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "bio") 	    AND len(influencerMeta.bio)    		  GTE 10 ) ? 4 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "experience") 	AND len(influencerMeta.experience)    GTE 10 ) ? 3 : 0  >

		<cfset initialScore += ( structKeyExists(influencerMeta, "media") 	AND listLen(influencerMeta.media, chr(7)) GTE 1 ) ? (( listLen(influencerMeta.media, chr(7)) GTE 2 ) ? 2 : 1 ) : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "award") 	AND listLen(influencerMeta.award, chr(7)) GTE 1 ) ? (( listLen(influencerMeta.award, chr(7)) GTE 2 ) ? 2 : 1 ) : 0  >
		
		<cfset initialScore += ( structKeyExists(influencerMeta, "freq_post") 	AND influencerMeta.freq_post    NEQ '' ) ? 3 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "freq_review") AND influencerMeta.freq_review  NEQ '' ) ? 3 : 0  >
		
		<cfset initialScore += ( structKeyExists(influencerMeta, "freq_post_social") AND influencerMeta.freq_post_social  NEQ '' ) ? 2 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "freq_post_video")  AND influencerMeta.freq_post_video   NEQ '' ) ? 1 : 0  >		

		<cfset initialScore +=  structKeyExists(influencerMeta, "meat_dairy") ? 1 : 0  >

		<cfset initialScore += ( structKeyExists(influencerMeta, "freq_cook")  		 AND influencerMeta.freq_cook   		NEQ '' ) ? 1 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "interest_organic") AND influencerMeta.interest_organic 	NEQ '' ) ? 1 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "freq_tea")  		 AND influencerMeta.freq_tea   			NEQ '' ) ? 1 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "freq_coffee")  	 AND influencerMeta.freq_coffee   		NEQ '' ) ? 1 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "freq_soda")  		 AND influencerMeta.freq_soda   		NEQ '' ) ? 1 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "freq_alcohol")  	 AND influencerMeta.freq_alcohol   		NEQ '' ) ? 1 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "rate_eco")  		 AND influencerMeta.rate_eco   			NEQ '' ) ? 1 : 0  >
		

		<cfset initialScore += ( structKeyExists(influencerMeta, "age")  		AND influencerMeta.age   	 NEQ '' ) ? 2 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "income")  	AND influencerMeta.income    NEQ '' ) ? 2 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "children")  	AND influencerMeta.children  NEQ '' ) ? 1 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "education")  	AND influencerMeta.education NEQ '' ) ? 1 : 0  >
		<cfset initialScore += ( structKeyExists(influencerMeta, "ethnicity")  	AND influencerMeta.ethnicity NEQ '' ) ? 1 : 0  >
		
		<cfset tagEntityTypeID = "30,31,32,33" >

		<cfloop list="#tagEntityTypeID#" index="element">

			<cfquery name="local.tag" datasource="#variables.datasource#">
				SELECT 	entityID 						 
					FROM tagging  
					WHERE userID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userID#">
						AND entityTypeID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#element#" >
			</cfquery>

			<cfif element EQ 30 >
				<cfset initialScore += ( local.tag.recordCount GTE 3 ) ? 3 : local.tag.recordCount >				
			</cfif>

			<cfif element EQ 31 OR element EQ 33 >
				<cfset initialScore += ( local.tag.recordCount GTE 5 ) ? 5 : local.tag.recordCount >				
			</cfif>

			<cfif element EQ 32 >
				<cfset initialScore += ( local.tag.recordCount GTE 6 ) ? 6 : local.tag.recordCount >
			</cfif>

		</cfloop>

		<cfset optionTypeID = "1,2,3,4,6" >

		<cfloop list="#optionTypeID#" index="element">
			
			<cfquery name="local.options" datasource="#variables.datasource#">
				SELECT optionID 
					FROM influencers_options 
					WHERE 
						userID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userID#" >
						AND optionTypeID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#element#" >
			</cfquery>

			<cfif element EQ 1 OR element EQ 2 OR element EQ 6 >
				<cfset initialScore += ( local.options.recordCount GTE 3 ) ? 3 : local.options.recordCount >
			</cfif>

			<cfif element EQ 3 OR element EQ 4 >
				<cfset initialScore += ( local.options.recordCount GTE 4 ) ? 4 : local.options.recordCount >
			</cfif>

		</cfloop>

		<cfquery name="local.channel" datasource="#variables.datasource#" >
			SELECT * FROM influencers_channel WHERE userID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userID#" >
		</cfquery>

		<cfset initialScore += ( local.channel.recordCount GTE 2 ) ? 2 : local.channel.recordCount >

		<cfquery name="local.cuisine" datasource="#variables.datasource#" >
			SELECT * FROM influencers_cuisine WHERE userID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userID#" >
		</cfquery>

		<cfset initialScore += ( local.cuisine.recordCount GTE 3 ) ? 3 : local.cuisine.recordCount >

		<cfquery name="local.diet" datasource="#variables.datasource#" >
			SELECT * FROM influencers_diet WHERE userID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userID#" >
		</cfquery>

		<cfset initialScore += ( local.diet.recordCount GTE 3 ) ? 3 : local.diet.recordCount >
		
		<cfquery name="local.allergy" datasource="#variables.datasource#" >
			SELECT * FROM influencers_allergy WHERE userID = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userID#" >
		</cfquery>

		<cfset initialScore += ( local.allergy.recordCount GTE 3 ) ? 3 : local.allergy.recordCount >

		<cfreturn initialScore >

	</cffunction>	


	<cffunction name="getRecipeScore" access="public" output="false">

		<cfargument name="recipeID" type="numeric" required="true">

		<cfset local.recipeStrength = 0>

		<cfquery name="local.query" datasource="#variables.datasource#">

			SELECT recipeTitle,
					recipeTotalServings,
					recipePrepTime,
					recipeCookTime,
					recipeTotalTime,
					recipeSourceSiteURL,
					recipeDesc 
				FROM recipes
				WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

		</cfquery>
		

		
			
		<cfif local.query.recordCount >

			<cfquery name="local.image" datasource="#variables.dataSource#">

				SELECT imageID FROM images 
					WHERE entityID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">
					AND entityTypeID = <cfqueryparam value="10" cfsqltype="cf_sql_integer">

			</cfquery>

			<cfquery name="local.style" datasource="#variables.dataSource#">

				SELECT Count(id) AS 'channels' FROM recipes_channel 
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

			</cfquery>

			<cfquery name="local.course" datasource="#variables.dataSource#">

				SELECT Count(id) AS 'course' FROM recipes_course
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

			</cfquery>

			<cfquery name="local.cuisine" datasource="#variables.dataSource#">

				SELECT Count(id) AS 'cuisine' FROM recipes_cuisine
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

			</cfquery>

			<cfquery name="local.diet" datasource="#variables.dataSource#">

				SELECT Count(id) AS 'diet' FROM recipes_diet
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

			</cfquery>

			<cfquery name="local.allergy" datasource="#variables.dataSource#">

				SELECT Count(id) AS 'allergy' FROM recipes_allergy
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

			</cfquery>

			<cfquery name="local.holiday" datasource="#variables.dataSource#">
				
				SELECT id FROM recipes_holiday
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

			</cfquery>

			<cfquery name="local.occasion" datasource="#variables.dataSource#">
				
				SELECT id FROM recipes_occasion
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

			</cfquery>

			<cfquery name="local.season" datasource="#variables.dataSource#">
				
				SELECT id FROM recipes_season
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

			</cfquery>

			<cfquery name="local.validIngredients" datasource="#variables.dataSource#">
					
	 			SELECT id FROM recipes_ingredientline
	 				WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">
	 				AND isMatch = 1

			</cfquery>

			<cfquery name="local.inValidIngredients" datasource="#variables.dataSource#">
					
	 			SELECT id FROM recipes_ingredientline
	 				WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">
	 				AND isMatch = 0

			</cfquery>

			<cfquery name="local.validDirecitions" datasource="#variables.datasource#">
				
				SELECT id FROM recipes_directions 
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">
					AND imageID <>'' AND imageID <> 0 AND imageID IS NOT NULL
					
			</cfquery>

			<cfquery name="local.inValidDirecitions" datasource="#variables.datasource#">
				
				SELECT id FROM recipes_directions  
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">
					AND imageID = 0 OR imageID IS NULL 
					
			</cfquery>
		
				<!--- recipe table values --->
				<cfset local.recipeStrength += 	( len( local.query.recipeTitle ) GTE 8 ) ? 8 : 0 >
				<cfset local.recipeStrength +=  len( local.query.recipeTotalServings )  ? 4 : 0 >
				<cfset local.recipeStrength +=  len( local.query.recipePrepTime ) ? 3 : 0 >
				<cfset local.recipeStrength +=  len( local.query.recipeCookTime ) ? 3 : 0 >
				<cfset local.recipeStrength +=  len( local.query.recipeTotalTime ) ? 3 : 0 >
				<cfset local.recipeStrength +=  len( local.query.recipeSourceSiteURL ) ? 2 : 0 >
				<cfset local.recipeStrength +=  len( local.query.recipeDesc ) GTE 10  ? 6 : 0 >

				<!--- image table values --->
				<cfset local.recipeStrength +=  local.image.recordCount ? 8 : 0 >

				<!--- recipe tags value --->
				
				<cfset local.recipeStrength +=  local.style.recordCount AND local.style.channels GT 0 ? 3 : 0 >
				<cfset local.recipeStrength +=  local.course.recordCount AND local.course.course GT 0 ? 2 : 0 >
				<cfset local.recipeStrength +=  local.cuisine.recordCount AND local.cuisine.cuisine GT 0 ? 3 : 0 >
				<cfset local.recipeStrength +=  local.diet.recordCount AND local.diet.diet GT 0 ? 2 : 0 >
				<cfset local.recipeStrength +=  local.allergy.recordCount AND local.allergy.allergy GT 0 ? 2 : 0 >
				<cfset local.recipeStrength +=  local.holiday.recordCount  GT 0 ? 1 : 0 >
				<cfset local.recipeStrength +=  local.occasion.recordCount  GT 0 ? 1 : 0 >
				<cfset local.recipeStrength +=  local.season.recordCount  GT 0 ? 1 : 0 >

				<!--- recipe ingredients strength --->
				<cfset validIngredientsStrenght = local.validIngredients.recordCount * 8>
				<cfset inValidIngredientsStrenght = local.inValidIngredients.recordCount >
				<cfset local.recipeStrength += (validIngredientsStrenght + inValidIngredientsStrenght) GTE 24 ? 24 : (validIngredientsStrenght + inValidIngredientsStrenght) > 
				
				<!--- recipe direcitions strength --->

				<cfset validDirectionStrength = local.validDirecitions.recordCount * 8>
				<cfset inValidDirecitionStrength = local.inValidDirecitions.recordCount * 6>

				<cfset local.recipeStrength += (validDirectionStrength + inValidDirecitionStrength) GTE 24 ? 24 : (validDirectionStrength + inValidDirecitionStrength)>
			

			<cfquery name="local.strength" datasource="#variables.dataSource#">
				
				UPDATE recipes SET recipeStrength = <cfqueryparam value="#local.recipeStrength#" cfsqltype="cf_sql_integer">
					WHERE recipeID = <cfqueryparam value="#arguments.recipeID#" cfsqltype="cf_sql_integer">

			</cfquery>

		</cfif>
		

		<cfreturn local.recipeStrength >

	</cffunction>

</cfcomponent>