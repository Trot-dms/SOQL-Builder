public with sharing class SOQLBuilder {

    private static String SYNTAX_SELECT = 'SELECT';
    private static String SYNTAX_FROM = 'FROM';
    private static String SYNTAX_WHERE = 'WHERE';
    private static String SYNTAX_GROUP_BY = 'GROUP BY';
    private static String SYNTAX_GROUP_BY_CUBE = 'GROUP BY CUBE';
    private static String SYNTAX_GROUP_BY_ROLLUP = 'GROUP BY ROLLUP';
    private static String SYNTAX_HAVING = 'HAVING';
    private static String SYNTAX_ORDER_BY = 'ORDER BY';
    private static String SYNTAX_LIMIT = 'LIMIT';
    private static String SYNTAX_OFFSET = 'OFFSET';

    private Set<String> fields;
    private String fromObject;
    private String[] orderBy;
    private String[] groupBy;
    private String[] havingConditions;
    private Boolean groupByCube;
    private Boolean groupByRollup;
    private String[] whereConditions;
    private String limitQueryPart;
    private String offsetQueryPart;


    public SOQLBuilder() {
        fields = new Set<String>();
        orderBy = new String[]{};
        groupBy = new String[]{};
        havingConditions = new String[]{};
        whereConditions = new String[]{};
    }

    public String build() {
        String fieldsQueryPart;
        String fromQueryPart;
        String whereQueryPart;
        String groupByQueryPart;
        String havingQueryPart;
        String orderByQueryPart;

        if (fields.isEmpty()) {
            fields.add('Id');
        }
        fieldsQueryPart = SYNTAX_SELECT + ' ' + String.join(new List<String>(fields), ', ');

        if (String.isEmpty(fromObject)) {
            throw new SOQLBuilderException('SOQL_SYNTAX_ERROR: FROM sObject not specified.');
        }

        if (!whereConditions.isEmpty()) {
            whereQueryPart = SYNTAX_WHERE + ' ' + String.join(whereConditions, ' ');
        }

        if (!groupBy.isEmpty()) {
            if (groupByRollup) {
                groupByQueryPart = SYNTAX_GROUP_BY_ROLLUP;
            } else if (groupByCube) {
                groupByQueryPart = SYNTAX_GROUP_BY_CUBE;
            } else {
                groupByQueryPart = SYNTAX_GROUP_BY;
            }
            groupByQueryPart += ' ' + String.join(groupBy, ', ');
        }

        if (!havingConditions.isEmpty()) {
            havingQueryPart = SYNTAX_HAVING + ' ' + String.join(havingConditions, ', ');
        }

        if (!orderBy.isEmpty()) {
            orderByQueryPart = SYNTAX_ORDER_BY + ' ' + String.join(orderBy, ', ');
        }

        String[] query = new String[]{
                fieldsQueryPart,
                fromObject,
                whereQueryPart,
                groupByQueryPart,
                havingQueryPart,
                orderByQueryPart,
                limitQueryPart,
                offsetQueryPart
        };

        return String.join(query, ' ');
    }

    public List<sObject> query() {
        return Database.query(build());
    }

    public Database.QueryLocator getQueryLocator() {
        return Database.getQueryLocator(this.build());
    }

    public SOQLBuilder fromObject(String fromObject) {
        this.fromObject = SYNTAX_FROM + ' ' + fromObject;
        return this;
    }

    public SOQLBuilder selectField(String field) {
        this.fields.add(field);
        return this;
    }

    public SOQLBuilder selectFields(String[] fields) {
        this.fields.addAll(fields);
        return this;
    }

    public SOQLBuilder addSubquery(SOQLBuilder subqueryBuilder) {
        String subQuery = String.join(
                new String[]{
                        '(', subqueryBuilder.build(), ')'
                }, ' ');

        this.fields.add(subQuery);
        return this;
    }

    public SOQLBuilder addSubquery(String subquery) {
        if (!subquery.startsWith('(') && !subquery.endsWith(')')) {
            subquery = '(' + subquery + ')';
        }
        this.fields.add(subquery);
        return this;
    }

    public SOQLBuilder limitOf(Integer limitOf) {
        if (limitOf < 0) {
            throw new SOQLBuilderException('JSON.deserializeUntyped()');
        } else {
            this.limitQueryPart = SYNTAX_LIMIT + ' ' + String.valueOf(limitOf);
        }

        return this;
    }

    public SOQLBuilder offsetOf(Integer offsetOf) {
        if (offsetOf < 0) {
            throw new SOQLBuilderException('NUMBER_OUTSIDE_VALID_RANGE: SOQL offset must be a non-negative value');
        } else {
            this.offsetQueryPart = SYNTAX_OFFSET + ' ' + String.valueOf(offsetOf);
        }
        return this;
    }

    public SOQLBuilder orderBy(String orderBy, String ascDesc) {
        this.orderBy.add(orderBy + ' ' + ascDesc.toUpperCase());
        return this;
    }

    public SOQLBuilder orderBy(String[] orderBy) {
        this.orderBy.addAll(orderBy);
        return this;
    }

    public SOQLBuilder groupBy(String[] groupBy) {
        if (this.groupByRollup) {
            throw new SOQLBuilderException('SOQL_SYNTAX_ERROR: You cant combine GROUP BY and GROUP BY ROLLUP syntax in the same statement.');
        }
        if (this.groupByCube) {
            throw new SOQLBuilderException('SOQL_SYNTAX_ERROR: You cant combine GROUP BY and GROUP BY CUBE syntax in the same statement.');
        }
        this.groupBy.addAll(groupBy);
        return this;
    }

    public SOQLBuilder groupByCube(String[] groupBy) {
        if (this.groupByRollup) {
            throw new SOQLBuilderException('SOQL_SYNTAX_ERROR: You cant combine GROUP BY ROLLUP and GROUP BY CUBE syntax in the same statement.');
        }
        this.groupByCube = true;
        this.groupBy.addAll(groupBy);
        return this;
    }

    public SOQLBuilder groupByRollup(String[] groupBy) {
        if (this.groupByCube) {
            throw new SOQLBuilderException('SOQL_SYNTAX_ERROR: You cant combine GROUP BY ROLLUP and GROUP BY CUBE syntax in the same statement.');
        }
        this.groupByRollup = true;
        this.groupBy.addAll(groupBy);
        return this;
    }

    public SOQLBuilder havingCondition(String havingConditionExpression) {
        this.havingConditions.add(havingConditionExpression);
        return this;
    }

    public SOQLBuilder whereAddToken(String condition) {
        this.whereConditions.add(condition);
        return this;
    }

    public SOQLBuilder whereAddTokens(String[] conditions) {
        this.whereConditions.addAll(conditions);
        return this;
    }

    public SOQLBuilder whereField(String field, String operator, Object value) {
        return whereField('', field, operator, value);
    }

    public SOQLBuilder whereField(String logicExp, String field, String operator, Object value) {
        String expression = logicExp + ' ' + SOQLUtils.whereField(field, operator, value);
        this.whereConditions.add(expression);
        return this;
    }

    public SOQLBuilder whereField(String field, String operator, Object[] value) {
        return whereField('', field, operator, value);
    }

    public SOQLBuilder whereField(String logicExp, String field, String operator, Object[] value) {
        String expression = logicExp + ' ' + SOQLUtils.whereField(field, operator, value);
        this.whereConditions.add(expression);
        return this;
    }

    public SOQLBuilder whereFieldIf(String logicExp, String field, String operator, Object value, Boolean condition) {
        if (condition) {
            this.whereField(logicExp, field, operator, value);
        }
        return this;
    }

    public SOQLBuilder whereFieldIf(String logicExp, String field, String operator, Object[] value, Boolean condition) {
        if (condition) {
            this.whereField(logicExp, field, operator, value);
        }
        return this;
    }

    public SOQLBuilder whereFieldIf(String field, String operator, Object[] value, Boolean condition) {
        return whereFieldIf('', field, operator, value, condition);
    }

    public SOQLBuilder whereFieldIf(String field, String operator, Object value, Boolean condition) {
        return whereFieldIf('', field, operator, value, condition);
    }

    public SOQLBuilder whereFieldIn(String field, String[] values) {
        this.whereConditions.add(SOQLUtils.whereFieldIn(field, values));
        return this;
    }

    public SOQLBuilder whereFieldNotIn(String field, String[] values) {
        this.whereConditions.add(SOQLUtils.whereFieldNotIn(field, values));
        return this;
    }

    public SOQLBuilder whereFieldEquals(String field, Object value) {
        this.whereConditions.add(SOQLUtils.whereFieldEquals(field, value));
        return this;
    }

    public SOQLBuilder whereFieldNotEquals(String field, Object value) {
        this.whereConditions.add(SOQLUtils.whereFieldNotEquals(field, value));
        return this;
    }

    public SOQLBuilder whereFieldLike(String field, String value) {
        this.whereConditions.add(SOQLUtils.whereFieldLike(field, value));
        return this;
    }

    public SOQLBuilder whereFieldNotLike(String field, String value) {
        this.whereConditions.add(SOQLUtils.whereFieldNotLike(field, value));
        return this;
    }

    public SOQLBuilder whereFieldIncludes(String field, String value) {
        this.whereConditions.add(SOQLUtils.whereFieldIncludes(field, value));
        return this;
    }

    public SOQLBuilder whereFieldIncludes(String field, String[] values) {
        this.whereConditions.add(SOQLUtils.whereFieldIncludes(field, values));
        return this;
    }

    public SOQLBuilder whereFieldNotIncludes(String field, String value) {
        this.whereConditions.add(SOQLUtils.whereFieldNotIncludes(field, value));
        return this;
    }

    public SOQLBuilder whereAND() {
        return this.whereAddToken('AND');
    }

    public SOQLBuilder whereOR() {
        return this.whereAddToken('OR');
    }

    public class SOQLBuilderException extends Exception {
    }
}