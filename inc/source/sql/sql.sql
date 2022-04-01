SELECT
    goods_id :: text AS code,
    ROUND(
        (
            CASE
                WHEN (
                    discount_id IS NOT NULL
                    AND (
                        discount_rate > 0
                        AND discount_rate < 99.99
                    )
                    AND markup_rate = 0
                ) THEN (
                    outcom_price - (outcom_price * discount_rate / 100)
                )
                WHEN (
                    discount_id IS NOT NULL
                    AND (
                        markup_rate > 0
                        AND markup_rate < 99.99
                    )
                    AND discount_rate = 0
                ) THEN (
                    (
                        incom_price + (incom_price * markup_rate / 100) * (
                            CASE
                                WHEN nds = 1 THEN 1.20
                                WHEN nds = 2 THEN 1
                                WHEN nds = 4 THEN 1.07
                                ELSE 1
                            END
                        )
                    )
                )
                WHEN (
                    CASE
                        WHEN fix_price IS NOT NULL THEN fix_price
                        WHEN rate >= 0 THEN (
                            incom_price * (rate / 100 + 1) * (
                                CASE
                                    WHEN nds = 1 THEN 1.20
                                    WHEN nds = 2 THEN 1
                                    WHEN nds = 4 THEN 1.07
                                    ELSE 1
                                END
                            )
                        )
                        WHEN rate < 0 THEN (
                            outcom_price - (outcom_price * (rate * (-1) / 100))
                        )
                        ELSE outcom_price
                    END
                ) > outcom_price THEN outcom_price
                WHEN (
                    CASE
                        WHEN fix_price IS NOT NULL THEN fix_price
                        WHEN rate >= 0 THEN (
                            incom_price * (rate / 100 + 1) * (
                                CASE
                                    WHEN nds = 1 THEN 1.20
                                    WHEN nds = 2 THEN 1
                                    WHEN nds = 4 THEN 1.07
                                    ELSE 1
                                END
                            )
                        )
                        WHEN rate < 0 THEN (
                            outcom_price - (outcom_price * (rate * (-1) / 100))
                        )
                        ELSE outcom_price
                    END
                ) < (outcom_price - (outcom_price * 0.2)) THEN (outcom_price - (outcom_price * 0.2))
                ELSE (
                    CASE
                        WHEN fix_price IS NOT NULL THEN fix_price
                        WHEN rate >= 0 THEN (
                            incom_price * (rate / 100 + 1) * (
                                CASE
                                    WHEN nds = 1 THEN 1.20
                                    WHEN nds = 2 THEN 1
                                    WHEN nds = 4 THEN 1.07
                                    ELSE 1
                                END
                            )
                        )
                        WHEN rate < 0 THEN (
                            outcom_price - (outcom_price * (rate * (-1) / 100))
                        )
                        ELSE outcom_price
                    END
                )
            END
        ) :: numeric,
        2
    ) AS price,
    count as quant,
    outcom_price AS "offlinePrice"
FROM
    (
        SELECT
            goods_conunt.goods_id AS goods_id,
            goods_conunt.count AS "count",
            goods_conunt.fix_price AS fix_price,
            (
                goods_conunt.incom_price_json :: json ->> update_date
            ) :: numeric as incom_price,
            (
                goods_conunt.outcom_price_json :: json ->> update_date
            ) :: numeric as outcom_price,
            (goods_conunt.nds_json :: json ->> update_date) :: numeric as nds,
            (
                CASE
                    WHEN goods_conunt.manufactor_discount IS NOT NULL THEN goods_conunt.manufactor_discount
                    WHEN goods_conunt.goods_type_discount IS NOT NULL THEN goods_conunt.goods_type_discount
                    ELSE (
                        CASE
                            WHEN (
                                SELECT
                                    percentage_of_markup
                                FROM
                                    percentage_rate
                                WHERE
                                    (
                                        goods_conunt.outcom_price_json :: json ->> update_date
                                    ) :: numeric BETWEEN price_from
                                    and price_to
                                LIMIT
                                    1
                            ) IS NULL THEN 10
                            ELSE (
                                SELECT
                                    percentage_of_markup
                                FROM
                                    percentage_rate
                                WHERE
                                    (
                                        goods_conunt.outcom_price_json :: json ->> update_date
                                    ) :: numeric BETWEEN price_from
                                    and price_to
                                LIMIT
                                    1
                            ) :: NUMERIC
                        END
                    )
                END
            ) AS rate,
            discount_promotion.discount_id AS discount_id,
            discount_promotion.discount_rate AS discount_rate,
            discount_promotion.markup_rate AS markup_rate
        FROM
            (
                SELECT
                    remnants.goods_id AS goods_id,
                    goods_.fix_price AS fix_price,
                    manufactor_.discount_percentage AS manufactor_discount,
                    goods_type_.discount_percentage AS goods_type_discount,
                    SUM(ROUND(remnants.count, 3)) AS "count",
                    > Denis Kulpa: json_object_agg(
                        remnants.update_date :: text,
                        remnants.incom_price
                    ) AS incom_price_json,
                    json_object_agg(
                        remnants.update_date :: text,
                        remnants.outcom_price
                    ) AS outcom_price_json,
                    json_object_agg(remnants.update_date :: text, remnants.nds) AS nds_json,
                    MIN(remnants.update_date) :: text AS update_date
                FROM
                    goods_remnants AS remnants
                    LEFT JOIN goods AS goods_ ON goods_.goods_id = remnants.goods_id
                    LEFT JOIN manufactor AS manufactor_ ON manufactor_.manufactor_id = goods_.manufactor_id
                    LEFT JOIN goods_type AS goods_type_ ON goods_type_.goods_type_id = goods_.goods_type_id
                WHERE
                    remnants.trade_pnt_id = 33
                    AND remnants.count > 0.001
                    AND remnants.outcom_price > 0.17
                    AND goods_.forbidden = 0
                GROUP BY
                    remnants.goods_id,
                    goods_.fix_price,
                    manufactor_.discount_percentage,
                    goods_type_.discount_percentage
            ) AS goods_conunt
            LEFT JOIN (
                SELECT
                    d_p_g.goods_id AS goods_id,
                    max(d_p.id) AS discount_id,
                    d_p.discount_rate AS discount_rate,
                    d_p.markup_rate AS markup_rate
                FROM
                    discount_promotion AS d_p
                    LEFT JOIN discount_promotion_goods AS d_p_g ON d_p_g.document_id = d_p.id
                WHERE
                    (
                        SELECT
                            value
                        FROM
                            properties_enable_disable
                        WHERE
                            key = 'DiscountAndPromotionLiki24'
                    ) = true
                    AND now() BETWEEN d_p.start_date
                    AND d_p.end_date
                    AND d_p.max_count = 0
                    AND d_p.max_summ = 0
                    AND d_p.min_count = 0
                    AND d_p.min_summ = 0
                GROUP BY
                    d_p_g.goods_id,
                    d_p.discount_rate,
                    d_p.markup_rate
            ) AS discount_promotion ON discount_promotion.goods_id = goods_conunt.goods_id
    ) AS goods_count_all