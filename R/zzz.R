# Package environment for storing session state
climenu_env <- new.env(parent = emptyenv())

# Declare global variables to satisfy R CMD check
utils::globalVariables("climenu_env")
