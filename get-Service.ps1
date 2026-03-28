get-service                                                               #(get's service OBJECTS on the computer (schedule) is an object og (get-service er en cmd-let)
get-service | get-member
get-service | get-member -membertype *property                                                                         #(Lister alle  properties of a service object)
get-service | get-member -membertype *method                                                     
get-service schedule | format-list -property *                                                                         #(Lister property værdier af objectet schedule)






