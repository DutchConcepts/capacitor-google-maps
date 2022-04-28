package com.hemangkumar.capacitorgooglemaps;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Picture;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.PictureDrawable;
import android.text.TextUtils;
import android.util.LruCache;
import android.util.Size;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.bumptech.glide.Glide;
import com.bumptech.glide.RequestBuilder;
import com.bumptech.glide.request.target.CustomTarget;
import com.bumptech.glide.request.transition.Transition;
import com.caverock.androidsvg.SVG;
import com.caverock.androidsvg.SVGParseException;
import com.getcapacitor.JSObject;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Locale;

class AsyncIconLoader {

    private static final int PICTURE_DOWNLOAD_TIMEOUT = 3000;
    private static final int FAST_CACHE_SIZE_ENTRIES = 32;

    private static final LruCache<String, Bitmap> bitmapCache = new LruCache<>(FAST_CACHE_SIZE_ENTRIES);

    public interface OnIconReady {
        void onReady(@Nullable Bitmap bitmap);
    }

    private final IconDescriptor iconDescriptor;
    private final Context context;

    public AsyncIconLoader(JSObject jsIconDescriptor, Context context) {
        this.iconDescriptor = new IconDescriptor(jsIconDescriptor);
        this.context = context;
    }

    public void load(OnIconReady onIconReady) {

        if (TextUtils.isEmpty(iconDescriptor.url)) {
            onIconReady.onReady(null);
            return;
        }
        String url = iconDescriptor.url.toLowerCase(Locale.ROOT);
        Bitmap cachedBitmap = bitmapCache.get(url);
        if (cachedBitmap != null) {
            onIconReady.onReady(cachedBitmap);
            return;
        }
        if (url.endsWith(".svg")) {
            loadSvg(onIconReady);
        } else {
            loadBitmap(onIconReady);
        }
    }

    private void loadBitmap(OnIconReady onIconReady) {
        RequestBuilder<Bitmap> builder = Glide.with(context)
                .asBitmap()
                .load(iconDescriptor.url)
                .timeout(PICTURE_DOWNLOAD_TIMEOUT);
        scaleImageOptional(builder).into(
                new CustomTarget<Bitmap>() {
                    // It will be called when the resource load has finished.
                    @Override
                    public void onResourceReady(
                            @NonNull Bitmap bitmap,
                            @Nullable Transition<? super Bitmap> transition) {
                        bitmapCache.put(iconDescriptor.url, bitmap);
                        onIconReady.onReady(bitmap);
                    }

                    // It is called when a loadAll is cancelled and its resources are freed.
                    @Override
                    public void onLoadCleared(@Nullable Drawable placeholder) {
                        // Use default marker
                        onIconReady.onReady(null);
                    }

                    // It is called when can't get image from network AND from a local cache.
                    @Override
                    public void onLoadFailed(@Nullable Drawable errorDrawable) {
                        // Use default marker
                        onIconReady.onReady(null);
                    }
                }
        );
    }

    private void loadSvg(OnIconReady onIconReady) {
        Glide.with(context).downloadOnly().load(iconDescriptor.url).into(new CustomTarget<File>() {
            @Override
            public void onResourceReady(@NonNull File resource, @Nullable Transition<? super File> transition) {
                try {
                    try (InputStream inputStream = new FileInputStream(resource)) {
                        SVG svg = SVG.getFromInputStream(inputStream);
                        Size sz = calcPictureSize();
                        if (sz.getWidth() > -1) {
                            svg.setDocumentWidth(sz.getWidth());
                            svg.setDocumentHeight(sz.getHeight());
                        }
                        Picture picture = svg.renderToPicture();
                        Bitmap bitmap = pictureToBitmap(picture);
                        bitmapCache.put(iconDescriptor.url, bitmap);
                        onIconReady.onReady(bitmap);
                    }
                } catch (IOException | SVGParseException exception) {
                    onIconReady.onReady(null);
                }
            }

            @Override
            public void onLoadCleared(@Nullable Drawable placeholder) {
                onIconReady.onReady(null);
            }

            @Override
            public void onLoadFailed(@Nullable Drawable errorDrawable) {
                onIconReady.onReady(null);
            }
        });
    }

    private Size calcPictureSize() {
        if (iconDescriptor.sizeInPixels.getHeight() > 0 && iconDescriptor.sizeInPixels.getWidth() > 0) {
            // Scale image to provided size in Pixels
            return new Size(iconDescriptor.sizeInPixels.getWidth(), iconDescriptor.sizeInPixels.getHeight());
        }
        // size is not set -> return (-1; -1)
        return new Size(-1, -1);
    }

    private <T> RequestBuilder<T> scaleImageOptional(
            RequestBuilder<T> builder) {
        Size sz = calcPictureSize();
        if (sz.getWidth() > -1) {
            builder = builder.override(sz.getWidth(), sz.getHeight());
        }
        return builder;
    }

    private static Bitmap pictureToBitmap(Picture picture) {
        PictureDrawable pictureDrawable = new PictureDrawable(picture);
        return pictureDrawableToBitmap(pictureDrawable);
    }

    private static Bitmap pictureDrawableToBitmap(PictureDrawable pictureDrawable) {
        Bitmap bmp = Bitmap.createBitmap(
                pictureDrawable.getIntrinsicWidth(),
                pictureDrawable.getIntrinsicHeight(),
                Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bmp);
        canvas.drawPicture(pictureDrawable.getPicture());
        return bmp;
    }
}
