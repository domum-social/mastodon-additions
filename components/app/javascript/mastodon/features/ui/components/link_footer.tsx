/**
 * Custom override of Mastodon's LinkFooter component
 *
 * DIFFERENCES FROM DISTRIBUTION VERSION:
 * - Added a "Learning site" link (/learn) as the first item of the instance
 *   section, before "About"
 * - Added a "Funding" link (/learn/about/funding) as the last item of the
 *   instance section
 *
 * Both use plain <a> rather than <Link>: /learn is served by nginx, not by
 * React Router.
 *
 * Based on: mastodon/app/javascript/mastodon/features/ui/components/link_footer.tsx @ v4.6.4
 * Upstream restructured this in 4.6 -- <p> plus DividingCircle became two
 * <section>s of <ul>/<li> using CSS modules, and the `multiColumn` prop became
 * `context`. DividingCircle no longer exists; do not reintroduce it.
 */

import { FormattedMessage } from 'react-intl';

import { Link } from 'react-router-dom';

import {
  domain,
  version,
  source_url,
  statusPageUrl,
  profile_directory as canProfileDirectory,
  termsOfServiceEnabled,
} from 'mastodon/initial_state';

import classes from './link_footer.module.scss';

export const LinkFooter: React.FC<{
  context?: 'default' | 'multi-column' | 'about';
}> = ({ context = 'default' }) => {
  const multiColumn = context === 'multi-column';

  return (
    <footer className={classes.wrapper} data-context={context}>
      <section>
        <h2 className={classes.heading}>{`${domain}:`}</h2>
        <ul className={classes.list}>
          {/* CUSTOM: "Learning site" link - not present in distribution version */}
          <li>
            <a href='/learn' target={multiColumn ? '_blank' : undefined}>
              <FormattedMessage
                id='footer.learning_site'
                defaultMessage='Learning site'
              />
            </a>
          </li>
          <li>
            <Link to='/about' target={multiColumn ? '_blank' : undefined}>
              <FormattedMessage
                id='footer.about_this_server'
                defaultMessage='About'
              />
              <span className='sr-only'> {domain}</span>
            </Link>
          </li>
          {statusPageUrl && (
            <li>
              <a href={statusPageUrl} target='_blank' rel='noopener'>
                <FormattedMessage id='footer.status' defaultMessage='Status' />
              </a>
            </li>
          )}
          {canProfileDirectory && (
            <li>
              <Link to='/directory'>
                <FormattedMessage
                  id='footer.directory'
                  defaultMessage='Profiles directory'
                />
              </Link>
            </li>
          )}
          <li>
            <Link
              to='/privacy-policy'
              target={multiColumn ? '_blank' : undefined}
              rel='privacy-policy'
            >
              <FormattedMessage
                id='footer.privacy_policy'
                defaultMessage='Privacy policy'
              />
            </Link>
          </li>
          {termsOfServiceEnabled && (
            <li>
              <Link
                to='/terms-of-service'
                target={multiColumn ? '_blank' : undefined}
                rel='terms-of-service'
              >
                <FormattedMessage
                  id='footer.terms_of_service'
                  defaultMessage='Terms of service'
                />
              </Link>
            </li>
          )}
          {/* CUSTOM: "Funding" link - not present in distribution version */}
          <li>
            <a
              href='/learn/about/funding'
              target={multiColumn ? '_blank' : undefined}
            >
              <FormattedMessage id='footer.funding' defaultMessage='Funding' />
            </a>
          </li>
        </ul>
      </section>
      <section>
        <h2 className={classes.heading}>Mastodon:</h2>
        <ul className={classes.list}>
          <li>
            <a href='https://joinmastodon.org' target='_blank' rel='noopener'>
              <FormattedMessage id='footer.about' defaultMessage='About' />
              <span className='sr-only'> Mastodon</span>
            </a>
          </li>
          <li>
            <a
              href='https://joinmastodon.org/apps'
              target='_blank'
              rel='noopener'
            >
              <FormattedMessage
                id='footer.get_app'
                defaultMessage='Get the app'
              />
            </a>
          </li>
          <li>
            <Link to='/keyboard-shortcuts'>
              <FormattedMessage
                id='footer.keyboard_shortcuts'
                defaultMessage='Keyboard shortcuts'
              />
            </Link>
          </li>
          <li>
            <a href={source_url} rel='noopener' target='_blank'>
              <FormattedMessage
                id='footer.source_code'
                defaultMessage='View source code'
              />
            </a>
          </li>
          <li className={classes.version}>v{version}</li>
        </ul>
      </section>
    </footer>
  );
};
