#' Function to parse de json file into a relational provenance database
#'
#' This contains the necessary function to read the json file containing
#' provenance information and insert this information into a relational database
#' @param con Connection to the provenance database
#' @param prov Path to the prov.json file
#' @keywords database, sql, creation, provenance, json
#' @export

## DB connection and functions #####
#con <- dbConnect(SQLite(), "~/prov_test.db")
#con <- dbConnect(SQLite(), "/home/mondelli/Dropbox/Artigos/2019/ER/database/er_model.db")

# Read prov.json
#prov_json <- fromJSON('~/Dropbox/Artigos/2019/ER/experiment/modelr/prov_script/prov.json', flatten=TRUE)

parserDB <- function(con, prov){
  ## Load libraries #####
  parserDB_lib <- c('jsonlite', 'DBI', 'RSQLite', 'stringr', 'pryr', 'qdapRegex', 'dplyr', 'gdata')
  lapply(parserDB_lib, require, character.only = TRUE)

  ## Read prov
  prov_json <- fromJSON(prov, flatten=TRUE)

  options(stringsAsFactors = FALSE)
  # Rdt entities
  rdt_entities <- names(prov_json$entity)
  get_entity_name <- function(x){ eval(parse(text=paste0('prov_json$entity$`',x,'`$`rdt:name`'))) }
  get_entity_type <- function(x){ eval(parse(text=paste0('prov_json$entity$`',x,'`$`rdt:type`'))) }
  get_function_name <- function(x){ eval(parse(text=paste0('prov_json$entity$`',x,'`$`name`'))) }

  # Rdt activities
  rdt_activities <- names(prov_json$activity)
  get_activity_name <- function(x){ eval(parse(text=paste0('prov_json$activity$`',x,'`$`rdt:name`'))) }

  # Rdt relations
  get_consumed <- function(x){ eval(parse(text=paste0('prov_json$used$`',x,'`'))) }

  rdt_generated <- names(prov_json$wasGeneratedBy)
  rdt_used <- names(prov_json$used)

  ## Script packages (with TODO) #####
  print('Loading packages')
  rdt_libs <- grep("((?:[a-z][a-z]+))(:)(l)", rdt_entities, perl=TRUE, value=TRUE)
  # Carregar as bibliotecas para a etapa das funções (reconhecer de onde a função vem)
  script_package_name <- c()
  for (i in 1:length(rdt_libs)){
    script_package_name[i] <- eval(parse(text=paste0('prov_json$entity$`',rdt_libs[i],'`$name')))
  }
  lapply(script_package_name, require, character.only = TRUE)

  ## Funções #####
  print('Functions')
  rdt_functions <- grep("((?:[a-z][a-z]+))(:)(f)", rdt_entities, perl=TRUE, value=TRUE)
  function_name <- sapply(X = rdt_functions, FUN = get_function_name)

  ## used [activity used entity][CONSUMED] #####
  rdt_consumed <- grep("((?:[a-z][a-z]+))(:)(dp)", rdt_used, perl=TRUE, value=TRUE) # Não considerando o fp que também é registrado como used
  consumed_info <- as.data.frame(sapply(X = rdt_consumed, FUN = get_consumed)) # Dataframe com as relações (id dos atributos)

  get_consumed_entities <- function(x){
    rdt_id <- eval(parse(text=paste0('consumed_info$`',x,'`$`prov:entity`')))
    return(get_entity_name(rdt_id))
  }
  consumed_entities <- as.data.frame(sapply(X = rdt_consumed, FUN = get_consumed_entities))
  colnames(consumed_entities) <- 'entities'; rownames(consumed_entities) <- c()

  get_consumed_activities <- function(x){
    rdt_id <- eval(parse(text=paste0('consumed_info$`',x,'`$`prov:activity`')))
    return(get_activity_name(rdt_id))
  }
  consumed_activities <- as.data.frame(sapply(X = rdt_consumed, FUN = get_consumed_activities))
  colnames(consumed_activities) <- 'activities'; rownames(consumed_activities) <- c()

  # Dataframe com relação consumed mais detalhada (não só os ids)
  consumed_df <- t(consumed_info)
  consumed_df <- cbind(consumed_df, consumed_activities)
  consumed_df <- cbind(consumed_df, consumed_entities)
  consumed_df$type <- 'consumed'

  ## wasGenerated [activity produced entity][PRODUCED]  #####
  rdt_produced <- grep("((?:[a-z][a-z]+))(:)(pd)", rdt_generated, perl=TRUE, value=TRUE)
  get_produced <- function(x){ eval(parse(text=paste0('prov_json$wasGeneratedBy$`',x,'`'))) }
  produced_info <- as.data.frame(sapply(X = rdt_generated, FUN = get_produced)) # Dataframe com as relações (id dos atributos)

  get_produced_entities <- function(x){
    rdt_id <- eval(parse(text=paste0('produced_info$`',x,'`$`prov:entity`')))
    return(get_entity_name(rdt_id))
  }
  produced_entities <- as.data.frame(sapply(X = rdt_produced, FUN = get_produced_entities))
  colnames(produced_entities) <- 'entities'; rownames(produced_entities) <- c()

  get_produced_activities <- function(x){
    rdt_id <- eval(parse(text=paste0('produced_info$`',x,'`$`prov:activity`')))
    return(get_activity_name(rdt_id))
  }
  produced_activities <- as.data.frame(sapply(X = rdt_produced, FUN = get_produced_activities))
  colnames(produced_activities) <- 'activities'; rownames(produced_activities) <- c()

  produced_df <- t(produced_info)
  produced_df <- cbind(produced_df, produced_activities)
  produced_df <- cbind(produced_df, produced_entities)
  produced_df$type <- 'produced'

  ## Whole provenance dataframe (consumed and produced) #####

  consumed_produced_df <- rbind(consumed_df, produced_df)
  consumed_produced_df$`prov:entity` <- unlist(consumed_produced_df$`prov:entity`)
  consumed_produced_df$`prov:activity` <- unlist(consumed_produced_df$`prov:activity`)

  #used_wasGenerated_df$function_name <- c('')

  ## Aggregate functions to consumes_produced_df

  rdt_function_consumed <- grep("((?:[a-z][a-z]+))(:)(fp)", rdt_used, perl=TRUE, value=TRUE) # Não considerando o fp que também é registrado como used
  get_function_consumed <- function(x){ eval(parse(text=paste0('prov_json$used$`',x,'`'))) }
  function_consumed_info <- as.data.frame(sapply(X = rdt_function_consumed, FUN = get_function_consumed))

  get_fun_consumed <- function(x){
    rdt_id <- eval(parse(text=paste0('function_consumed_info$`',x,'`$`prov:entity`')))
    return(get_function_name(rdt_id))
  }
  consumed_functions <- as.data.frame(sapply(X = rdt_function_consumed, FUN = get_fun_consumed))
  colnames(consumed_functions) <- 'function_name'; rownames(consumed_functions) <- c()

  function_consumed_df <- t(function_consumed_info)
  function_consumed_df <- cbind(function_consumed_df, consumed_functions)[,c(2,3)]
  function_consumed_df$`prov:activity` <- unlist(function_consumed_df$`prov:activity`)
  rownames(function_consumed_df) <- c()

  # Merge prov with functions
  consumed_produced_df <- unique(merge(consumed_produced_df, function_consumed_df, all = T))

  ## Match function name ####

  for (i in 1:length(function_name)){
    grep <- grepl(function_name[i], consumed_produced_df$activities)
    which(grep == TRUE)
    consumed_produced_df$function_name[which(grep == TRUE)] <- function_name[i]
  }

  withoutFunction <- consumed_produced_df[which(is.na(consumed_produced_df$function_name)),] # Pegar atividades sem função identificada pela proveniência
  consumed_produced_df <- consumed_produced_df[-which(is.na(consumed_produced_df$function_name)),] # Excluir essas funções do df original
  #grep(pattern='.*\\(', x=withoutFunction$activities)
  for (i in 1:length(withoutFunction$activities)) {
    if (!grepl("<-", withoutFunction$activities[i], fixed=TRUE) & !grepl("(", withoutFunction$activities[i], fixed=TRUE)){
      withoutFunction_name <- 'no function specified'
    } else if (grepl("<-", withoutFunction$activities[i], fixed=TRUE) & !grepl("(", withoutFunction$activities[i], fixed=TRUE)){
      withoutFunction_name <- 'no function specified'
    } else if (!grepl("<-", withoutFunction$activities[i], fixed=TRUE)) {  # Pegar nome das funções não identificadas
      withoutFunction_name <- gsub("\\(.*","", withoutFunction$activities[i])
    } else {
      withoutFunction_name <- as.vector(unlist(rm_between(withoutFunction$activities[i], '<-', '(', extract=TRUE)))
    }
      withoutFunction$function_name[i] <- withoutFunction_name # Associar às atividades
  }
  consumed_produced_df <- rbind(consumed_produced_df, withoutFunction) # Juntar os dfs

  # Get functions and package names
  functions <- unique(consumed_produced_df$function_name)
  functions <- unique(append(functions, function_name), na.rm=TRUE)
  functions <- functions[!is.na(functions)]
  getFunctionPackage_function <- function(x){ print(x);
    if (x != 'no function specified')
      return(sub('.*\\:', '', environmentName(pryr::where(x))))
    else return('no package')
  } # Pegar pacote ao qual a função pertence
  functionPackage <- as.data.frame(sapply(X = functions, FUN = getFunctionPackage_function)) # Transformar em dataframe
  functionPackage$function_name <- rownames(functionPackage); rownames(functionPackage) <- c(); colnames(functionPackage) <- c('package', 'function_name') # Editar dataframe para poder juntar com wasGeneratedBy

  # Get entity type
  colnames(consumed_produced_df)[1] <- 'prov.activity'; colnames(consumed_produced_df)[2] <- 'prov.entity';
  entity_type <- data.frame(type_entity = unlist(
    sapply(X = consumed_produced_df$prov.entity, FUN = get_entity_type)),
    prov.entity = consumed_produced_df[which(!is.na(consumed_produced_df$prov.entity)),2]
                            )
  rownames(entity_type) <- c()

  # Dataframe com output (entity), function (activity), function_package - Produced
  consumed_produced_df <- unique(merge(consumed_produced_df, entity_type, by='prov.entity', all = T))
  consumed_produced_df <- merge(consumed_produced_df, functionPackage, all = T)

  ## Script #####
  script_pos <- names(which(1 * sapply(prov_json$activity, '%in%', x = 'Start') == 1)) # Posição do json que indica o script
  script_name <- eval(parse(text=paste0('prov_json$activity$`',script_pos,'`$`rdt:name`')))
  script_duration <- eval(parse(text=paste0('prov_json$activity$`',script_pos,'`$`rdt:elapsedTime`')))

  ## OS and packages ####
  # OS
  os_info <- data.frame(info=trim(system('hostnamectl', intern = T)))
  os_info <- strsplit(as.character(os_info$info),':')
  os_info <- as.data.frame(do.call(rbind, os_info)); os_info

  # Packages
  packages <- read.csv('/home/mondelli/Dropbox/Artigos/2019/ER/experiment/util/.diff.log', sep = " ", header = F)
  packages <- packages[packages$V5 == '[installed]',]
  packages <- packages[,2]
  packages <- gsub("\\/.*","",packages)

  get_pkg_version <- function(x){ system(paste0("dpkg -l | grep -i ", x, " | awk -v OFS=',' '{ print $2, $3 }'"), intern = T) }
  package_version <- sapply(X = packages, FUN = get_pkg_version)
  package_version <- as.data.frame(do.call(rbind, package_version))
  package_version <- strsplit(as.character(package_version$V1),','); package_version <- as.data.frame(do.call(rbind, package_version))

  package_r <- system('apt list --installed | grep r-base/', intern = T)
  package_r <- gsub("\\/.*","",package_r)
  version_r <- system("dpkg -l | grep 'r-base\\s' | awk -v OFS=',' '{ print $3 }'", intern=T)

  # Parameters
  script_content <- readLines('~/Dropbox/Artigos/2019/ER/experiment/modelr/prov_script/scripts/script.R')

  activity_param <- data.frame(prov.activity = c(), param = c())
  for (i in 2:(length(rdt_activities)-1)){
    startLine <- prov_json[["activity"]][[rdt_activities[i]]][["rdt:startLine"]]
    endLine <- prov_json[["activity"]][[rdt_activities[i]]][["rdt:endLine"]]

    args <- paste(trim(script_content[(startLine):(endLine)]), collapse=" ")

    activity_param <- rbind(activity_param, data.frame(prov.activity = rdt_activities[i], param = args))
  }

  consumed_produced_df <- merge(consumed_produced_df, activity_param)
  functions_parameters <- unique(consumed_produced_df[,c(1, 2, 9)])

  # Hardware info
  hardware_info <- system('lshw -short', intern=T)
  class_pos <- gregexpr(pattern ='Class',hardware_info[1])[[1]][1]
  hardware_info <- hardware_info[-c(1,2)]
  hardware_info <- substr(hardware_info, class_pos, 3000)
  hardware_info <- gsub("[[:blank:]]+", " ", hardware_info)
  class <- gsub("([A-Za-z]+).*", "\\1", hardware_info)
  description <- trimws(sub(hardware_info, pattern = "((?:[a-z][a-z]+))", replacement = ""))
  hw_info <- data.frame(class = class, description = description)
  description <- as.character(paste0(class, ' - ', description))
  description <- paste(description, collapse = ", ")

  # User
  user <- system("who | cut -d' ' -f1 | sort | uniq", intern = T)

  ## DB inserts #####
  # 0 - script
  dbSendQuery(con, paste0('insert into script (script_name, duration)
                            values ("',script_name ,'","',script_duration,'")'))
  script_id <- dbGetQuery(con, 'select max(script_id) from script')

  # 1 - hardware
  dbSendQuery(con, paste0('insert into hardware (description)
                            values ("',description,'")'))
  hw_id <- dbGetQuery(con, 'select max(hardware_id) from hardware')

  # 2 - os
  dbSendQuery(con, paste0('insert into os (name, platform, hardware_id)
                            values ("',os_info$V2[6] ,'","',os_info$V2[8],'","',hw_id,')'))
  os_id <- dbGetQuery(con, 'select max(os_id) from os')

  # 3 - user
  dbSendQuery(con, paste0('insert into user (name, os_id)
                          values ("',user,'",',os_id,')'))

  # 4 - os_packages
  insert_ospackages <- function(x,y){
    dbSendQuery(con, paste0('insert into os_package (os_package_name, version, os_id, script_id)
                            values ("', x['V1'] ,'","', x['V2'] ,'","',
                            os_id ,'","',script_id,'")'))}
  #insert_ospackages(package_version$V1, package_version$V2) #TODO: sapply
  apply(X = package_version, 1, FUN = insert_ospackages)
  # insert r package
  dbSendQuery(con, paste0('insert into os_package (os_package_name, version, os_id, script_id)
                            values ("', package_r,'","', version_r ,'","',
                          os_id ,'","',script_id,'")'))
  r_id <- dbGetQuery(con, paste0('select os_package_id from os_package where os_package_name like "', package_r,'"'))

  # 5 - script_packages
  for (i in 1:length(rdt_libs)){
    script_package_name <- eval(parse(text=paste0('prov_json$entity$`',rdt_libs[i],'`$name')))
    script_package_version <- eval(parse(text=paste0('prov_json$entity$`',rdt_libs[i],'`$version')))
    # Insert
    dbSendQuery(con, paste0('insert into script_package (script_package_name, version, os_package_id)
                            values ("',script_package_name ,'","',script_package_version,'","', r_id ,'")'))
  }
  dbSendQuery(con, paste0('insert into script_package (script_package_name, version, os_package_id)
                            values ("no package","","', r_id ,'")'))

  # 6 - input_output
  input_output <- na.omit(unique(dplyr::select(consumed_produced_df, entities, type_entity))) # unique(consumed_produced_df[, 5]))
  insert_input <- function(x) { dbSendQuery(con, paste0('insert into input_output (name, type) values ("', x['entities'] ,'","', x['type_entity'],'")')) }
  apply(X = input_output, 1, FUN = insert_input)

  # 7 - functions
  func <- unique(dplyr::select(consumed_produced_df, function_name, package))
  func <- func[!is.na(func$function_name),]
  insert_functions <- function(x) { dbSendQuery(con, paste0('insert into function (name, script_id, script_package_id)
                                                            select "',x['function_name'],'", ',script_id,', script_package_id from script_package where
                                                            script_package_name = "',x['package'],'"'))}
  apply(X = func, 1, FUN = insert_functions)

  # 4 - consumed
  c <- unique(dplyr::select(consumed_produced_df[which(consumed_produced_df$type == 'consumed'),],
                     function_name, entities, param))
  c$function_name <- as.character(c$function_name)
  c$entities <- as.character(c$entities)
  c$param <- as.character(c$param)
  c$param <- gsub('\"', "'", c$param)
  insert_consumed <- function(x){ print(x)
                                  f_id <- dbGetQuery(con, paste0('select function_id from function where name = "',x['function_name'],'"'));
                                  i_id <- dbGetQuery(con, paste0('select input_output_id from input_output where name = "',x['entities'],'"'));
                                  dbSendQuery(con, paste0('insert into consumed (input_id, function_id, parameters)
                                                          values (',i_id,',',f_id,',"',x['param'],'")'))
                                  }
  apply(X = c[which(!is.na(c$function_name)),], 1, FUN = insert_consumed)

  # 5 - produced

  p <- unique(dplyr::select(consumed_produced_df[which(consumed_produced_df$type == 'produced'),],
                     function_name, entities))

  insert_produced <- function(x){ print(x)
                                  f_id <- dbGetQuery(con, paste0('select function_id from function where name = "',as.character(x['function_name']),'"'))
                                  i_id <- dbGetQuery(con, paste0('select input_output_id from input_output where name = "',as.character(x['entities']),'"'))
                                  dbSendQuery(con, paste0('insert into produced (output_id, funtion_id)
                                                          values (',i_id,',',f_id,')'))}
  apply(X = p, 1, FUN = insert_produced)
  print('Finishing importing provenance to db.')
}




