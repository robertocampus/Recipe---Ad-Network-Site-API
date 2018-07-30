<cfcomponent extends="taffyAPI.base">
	
	<!--- :: Validate Arguments :: --->
	<cffunction name="preArgumentValidations" access="package" returntype="any">

		<cfset result.Errors = structNew() />
		<cfset listOfArgKeys = structKeyList(arguments)  >
		<cfset functionArguments = '' >
		<cfset defaultArgumentList = "init,CFC,_,VERB,endpoint,authorize,auth_token,fieldnames,NotAuthorize" >

		<cfset arg =  application["meta"][arguments.cfc][arguments.verb].parameters >

		<cfloop index="argList" array="#arg#">
			<cfset functionArguments = listAppend( functionArguments, argList.name ) >			
		</cfloop>		

		<cfloop index="argList" list="#listOfArgKeys#">
			<cfif NOT listFindNoCase(defaultArgumentList, argList ) AND NOT listFindNoCase(functionArguments, argList)>
				<cfset structInsert( result.Errors, argList, "Invalid argument.") >
			</cfif>
		</cfloop>

		<cfloop index="argList" array="#arg#">
			<cfset local.name 		= argList.name >			
			<cfset local.required 	= argList.required >
			<cfset local.type 		= argList.type >
			
			<cfif structKeyExists(arguments, name)>
				<cfset local.value 	= arguments[name] >
			</cfif>

			<cfif local.required AND ( NOT structKeyExists(local, "value") OR NOT trim(len(local.value)) ) AND NOT structKeyExists(arguments, "NotAuthorize") >

				<cfset structInsert(result.Errors, local.name, "This parameter is required") >
			
			<cfelseif structKeyExists(local, "value") >

				<cfif local.type EQ "numeric" AND NOT isNumeric(local.value) >					
					<cfset structInsert( result.Errors,  local.name, "This parameter value should be in integer.") >
				<cfelseif local.type EQ "boolean" AND NOT isBoolean(local.value) >
					<cfset structInsert( result.Errors,  local.name, "This parameter value should be in boolean.") >					
				</cfif>				

			</cfif>

			<cfset structClear(local) >
		</cfloop>		

		<cfset result.status = structCount(result.Errors) GT 0 ? false : true >

		<cfreturn result />		
	</cffunction>	
	
</cfcomponent> 