<?xml version="1.0" encoding="UTF-8"?>
<StyledLayerDescriptor version="1.0.0" xmlns="http://www.opengis.net/sld"
                       xmlns:ogc="http://www.opengis.net/ogc"
                       xmlns:xlink="http://www.w3.org/1999/xlink"
                       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                       xsi:schemaLocation="http://www.opengis.net/sld
                      http://schemas.opengis.net/sld/1.0.0/StyledLayerDescriptor.xsd">

    <NamedLayer>
        <Name>example</Name>
        <UserStyle>
            <sld:Name>Example Style</sld:Name>
            <sld:Title>Example Style</sld:Title>
            <Abstract>Yellow fill for example polygons</Abstract>
            <FeatureTypeStyle>
                <Rule>
                    <Name>example</Name>
                    <PolygonSymbolizer>
                        <Fill>
                            <CssParameter name="fill">#E6E600</CssParameter>
                        </Fill>
                    </PolygonSymbolizer>
                </Rule>
            </FeatureTypeStyle>
        </UserStyle>
    </NamedLayer>
</StyledLayerDescriptor>
