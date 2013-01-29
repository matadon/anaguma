## Kusuri: Flexible search for SQL, MongoDB, Solr, and more.

*This gem is currently in-development and pre-release.*

Kusuri implements a search parser and compiler for converting user-provided
searches into queries against a variety of backends, such as ActiveRecord,
Sequel, MongoDB, Solr and ElasticSearch.

The user-facing search syntax is similar to the Google search syntax,
including boolean logic and infix comparison operators.

Kusuri was designed so that an application can expose a standard search
syntax, one that is guaranteed to never return a syntax error to the
end-user, in the same way that even a Google search that makes no sense will
try and return at least something of value.

This approach also allows for greater flexibility, as you can migrate
backends when necessary, or even easily combine inverted indexes or search
services with traditional databases. Additionally, because you have complete
control over the way backend queries are compiled, you can filter and limit
results in a fine-grained fashion.
